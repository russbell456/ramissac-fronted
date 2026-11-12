import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/core/storage/session_storage.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_local_model.dart';
import 'package:sistema_ocs/features/rq_urgente/urgent_rq_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/non_catalogued_product_form_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/services/urgent_rq_service.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_status.dart';

class FakeService extends UrgentRQService {
  @override
  Future<List<Map<String, dynamic>>> obrasActivas() async => [
        {'id': 7, 'nombre': '010-2026 - Canales', 'descripcion': 'Canales'},
        {'id': 9, 'nombre': '011-2026 - Otra obra'},
      ];
  @override
  Future<List<Map<String, dynamic>>> buscarProductos(String query) async => [
        {
          'id': 2,
          'nombre':
              'Material de nombre bastante largo para probar el ajuste en pantalla',
          'unidad_medida': 'KG',
          'stock_actual': 0
        },
      ];
}

class ApiAdapter implements HttpClientAdapter {
  final List<String> calls = [];
  Map<String, dynamic> state = {
    'id': 20,
    'numero': 'RQ-020-2026',
    'estado': 'BORRADOR'
  };
  int sends = 0;
  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<List<int>>? requestStream, Future<dynamic>? cancelFuture) async {
    calls.add('${options.method} ${options.path}');
    if (options.path == '/almacen/obra/') {
      return ResponseBody.fromString(
          jsonEncode([
            {'id': 3, 'nombre': 'Activa', 'estado': 'activo'},
            {'id': 4, 'nombre': 'Cerrada', 'estado': 'cerrado'},
          ]),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    if (options.path.endsWith('/firmar-y-enviar')) {
      sends++;
      state['estado'] = 'FIRMADO';
      return ResponseBody.fromString('{"detail":"SMTP no disponible"}', 502,
          headers: {
            Headers.contentTypeHeader: ['application/json']
          });
    }
    if (options.path.endsWith('/reenviar')) state['estado'] = 'ENVIADO';
    return ResponseBody.fromString(jsonEncode(state), 200, headers: {
      Headers.contentTypeHeader: ['application/json']
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('obra por código, unidad libre, detalle y adjuntos llegan al payload',
      () {
    final rq = RQLocal(
        servicio: 'Texto libre',
        productosJson: '[{"nombre":"Tubo","unidad":"M","cantidad":2.5}]',
        fecha: '2026-10-01');
    expect(() => UrgentRQService.datosRequerimiento(rq), throwsStateError);
    rq.obraCodigo = '010-2026';
    rq.obraDescripcion = 'Canales';
    rq.productosJson = jsonEncode([
      {
        'articulo_id': 2,
        'nombre': 'Tubo',
        'unidad': 'M',
        'cantidad': 2.5,
        'medidas': '24 mm',
        'categoria': 'Herramienta',
        'adjuntos': [
          {
            'nombre': 'Ficha.pdf',
            'tipo_mime': 'application/pdf',
            'contenido_base64': 'JVBERi0='
          },
        ]
      }
    ]);
    final data = UrgentRQService.datosRequerimiento(rq);
    expect(data['obra_codigo'], '010-2026');
    expect(data['obra_descripcion'], 'Canales');
    expect(data.containsKey('obra_id'), false);
    expect(data.containsKey('nombre_proyecto'), false);
    final item = (data['items'] as List).single as Map;
    expect(item['descripcion'], 'Tipo: Herramienta\nMedidas: 24 mm');
    expect((item['adjuntos'] as List).single['nombre'], 'Ficha.pdf');
  });

  test('obras cerradas no se ofrecen y un reintento conserva el mismo RQ',
      () async {
    await const SessionStorage().write(key: 'jwt_token', value: 'test-token');
    final adapter = ApiAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = adapter;
    final service = UrgentRQService(dio: dio);
    expect((await service.obrasActivas()).map((o) => o['id']), [3]);
    final rq = RQLocal(
        obraId: 3,
        servicio: 'Activa',
        productosJson: '[{"articulo_id":2,"cantidad":1}]',
        fecha: '2026-10-01');
    final savedIds = <int?>[];
    await expectLater(
        service.enviar(rq, Uint8List.fromList([1, 2]), () async {
          savedIds.add(rq.servidorId);
        }),
        throwsA(isA<DioException>()));
    expect(rq.servidorId, 20);
    expect(rq.estadoServidor, 'FIRMADO');
    expect(savedIds.first, 20);
    await service.enviar(rq, null, () async {});
    expect(rq.enviado, 1);
    expect(adapter.calls.where((c) => c == 'POST /rq-campo').length, 1);
    expect(adapter.calls, contains('POST /rq-campo/20/reenviar'));
  });

  for (final width in [320.0, 800.0]) {
    testWidgets(
        'obra existente, stock cero y selección sin desbordes a $width px',
        (tester) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: UrgentRQScreen(service: FakeService())));
      await tester.pumpAndSettle();
      expect(find.text('Proyecto o servicio'), findsNothing);
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Código de obra *'), '010-2026');
      await tester.pumpAndSettle();
      expect(find.text('Canales'), findsOneWidget);
      await tester.tap(find.text('Buscar en catálogo'));
      await tester.pumpAndSettle();
      expect(find.text('Sin stock · se puede solicitar'), findsOneWidget);
      await tester.tap(find.byTooltip('Agregar producto'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Cantidad (KG)'), '2,5');
      await tester.tap(find.text('Agregar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Listo'));
      await tester.pumpAndSettle();
      expect(find.text('Productos (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('cantidades decimales y edición mantienen producto catalogado',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: NonCataloguedProductFormScreen(producto: {
          'articulo_id': 2,
          'nombre': 'Tubo',
          'unidad': 'M',
          'cantidad': 2.5,
        })));
    await tester.pumpAndSettle();
    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields.first.readOnly, true);
    expect(
        fields
            .where((f) => f.decoration?.labelText == 'Cantidad *')
            .single
            .controller!
            .text,
        '2.5');
    expect(find.text('Tipo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('filtros distinguen borradores, atención y finalizados', () {
    expect(coincideEstadoRq('FINALIZADO', 'Finalizados'), true);
    expect(coincideEstadoRq('EN_PROCESO', 'Enviados'), true);
    expect(coincideEstadoRq('FIRMADO', 'Pendientes'), true);
    expect(coincideEstadoRq('FINALIZADO', 'Enviados'), false);
    expect(esCompras('supervisor'), false);
    expect(esLogistica('almacenero'), true);
  });

  testWidgets('producto libre conserva unidad personalizada y un solo detalle',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: NonCataloguedProductFormScreen(producto: {
          'nombre': 'Cemento',
          'cantidad': 2,
          'unidad': 'bolsas',
          'medidas': '25 kg',
          'especificaciones': 'Tipo I',
          'observacion': 'Para canales',
        })));
    await tester.pumpAndSettle();
    expect(find.text('Medidas'), findsNothing);
    expect(find.text('Especificaciones técnicas'), findsNothing);
    expect(find.text('bolsas'), findsOneWidget);
    final detalle = tester
        .widget<TextFormField>(find.widgetWithText(TextFormField, 'Detalle'));
    expect(detalle.controller!.text, contains('25 kg'));
    expect(detalle.controller!.text, contains('Tipo I'));
    expect(detalle.controller!.text, contains('Para canales'));
    expect(tester.takeException(), isNull);
  });

  test('borradores anteriores conservan contenido y exigen elegir obra', () {
    final old = RQLocal.fromMap({
      'id': 1,
      'servicio': 'Obra anterior',
      'productos': '[]',
      'fecha': '2026-09-01',
      'enviado': 0
    });
    expect(old.obraId, null);
    expect(old.servicio, 'Obra anterior');
    final copy = RQLocal.fromMap(old.toMap());
    expect(copy.productosJson, old.productosJson);
  });
}
