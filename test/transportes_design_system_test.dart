import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/core/design_system/ramis_design_system.dart';
import 'package:sistema_ocs/data/models/user_model.dart';
import 'package:sistema_ocs/features/transportes/data/repositories/transporte_repository_impl.dart';
import 'package:sistema_ocs/features/transportes/domain/entities/jornada_transporte.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/admin_transportes_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/conductor_jornada_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/mi_jornada_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/screens/vehiculo_detalle_screen.dart';
import 'package:sistema_ocs/features/transportes/presentation/widgets/fuel_gauge_selector.dart';
import 'package:sistema_ocs/features/transportes/providers/admin_transportes_provider.dart';
import 'package:sistema_ocs/features/transportes/providers/documentos_provider.dart';
import 'package:sistema_ocs/features/transportes/providers/jornadas_provider.dart';

const _vehicle = <String, dynamic>{
  'id': 5,
  'placa': 'Z7F-777',
  'marca': 'Hino',
  'modelo': 'Camión grúa',
  'estado_semaforo': 'amarillo',
  'kilometraje_actual': 5000,
};

class _Repository extends TransporteRepositoryImpl {
  _Repository() : super(Dio());
  @override
  Future<dynamic> getV3(String path) async => [];
}

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  ThemeMode mode = ThemeMode.light,
  Size size = const Size(360, 800),
  double scale = 1,
  List<Override> overrides = const [],
  GlobalKey? captureKey,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      transporteRepositoryProvider.overrideWithValue(_Repository()),
      currentUserForTransportProvider.overrideWith((ref) async => UserModel(
            id: 7,
            nombre: 'Ana',
            apellidos: 'Ramis',
            email: 'ana@example.com',
            role: 'conductor',
            activo: true,
          )),
      accionesRegistradasProvider.overrideWith((ref) async => []),
      vehiculoJornadaProvider(5).overrideWith((ref) async => _vehicle),
      documentosProvider((entidad: 'vehiculo', id: 5))
          .overrideWith((ref) async => []),
      documentosProvider((entidad: 'conductor', id: 7))
          .overrideWith((ref) async => []),
      jornadasListProvider.overrideWith((ref) async => []),
      vehiculosListProvider.overrideWith((ref) async => [_vehicle]),
      mantenimientosListProvider.overrideWith((ref) async => []),
      averiasListProvider.overrideWith((ref) async => []),
      incidentesListProvider.overrideWith((ref) async => []),
      rutasListProvider.overrideWith((ref) async => []),
      conductoresV3Provider.overrideWith((ref) async => []),
      ...overrides,
    ],
    child: RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
        theme: RamisTheme.light,
        darkTheme: RamisTheme.dark,
        themeMode: mode,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  ));
}

// Optional local visual evidence; regular CI only asserts layout and behavior.
Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('TRANSPORTES_SCREENSHOTS')) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/transportes-review');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Variable.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await inter.load();
    await icons.load();
  });
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final size in [const Size(360, 800), const Size(1280, 900)]) {
      testWidgets(
          'Jornada activa ${mode.name} ${size.width} con texto ampliado',
          (tester) async {
        final key = GlobalKey();
        await _pump(tester, const ConductorJornadaScreen(),
            mode: mode,
            size: size,
            scale: 1.5,
            captureKey: key,
            overrides: [
              miJornadaProvider.overrideWith((ref) async => JornadaTransporte(
                    id: 10,
                    conductorId: 7,
                    vehiculoId: 5,
                    estado: 'en_curso',
                    kmInicial: 5000,
                    nivelCombustible: 75,
                    fechaInicio: DateTime.now(),
                  )),
            ]);
        await tester.pumpAndSettle();
        expect(find.text('Mi jornada en curso'), findsOneWidget);
        expect(find.byType(NavigationDestination), findsNWidgets(3));
        expect(tester.takeException(), isNull);
        await _capture(
            tester, key, 'jornada-${mode.name}-${size.width.toInt()}');
        await tester.pumpWidget(const SizedBox.shrink());
      });
      testWidgets('Documentos de vehículo ${mode.name} ${size.width}',
          (tester) async {
        final key = GlobalKey();
        await _pump(tester, const VehiculoDetalleScreen(vehiculo: _vehicle),
            mode: mode, size: size, scale: 1.5, captureKey: key);
        await tester.pumpAndSettle();
        expect(find.text('Vehículo Z7F-777'), findsOneWidget);
        expect(find.text('Descargar Ficha Técnica PDF'), findsOneWidget);
        expect(find.byType(RamisStatusChip), findsWidgets);
        expect(tester.takeException(), isNull);
        await _capture(
            tester, key, 'vehiculo-${mode.name}-${size.width.toInt()}');
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
    testWidgets('Administración conserva sus seis destinos en ${mode.name}',
        (tester) async {
      await _pump(tester, const AdminTransportesScreen(),
          mode: mode, scale: 1.5);
      await tester.pumpAndSettle();
      expect(find.byType(Tab), findsNWidgets(6));
      final controller =
          DefaultTabController.of(tester.element(find.byType(TabBar)));
      for (var index = 0; index < 6; index++) {
        controller.animateTo(index);
        await tester.pumpAndSettle();
        expect(controller.index, index);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('Jornada muestra carga, error, reintento y vacío',
      (tester) async {
    final request = Completer<JornadaTransporte?>();
    var attempts = 0;
    await _pump(tester, const MiJornadaScreen(), overrides: [
      miJornadaProvider.overrideWith((ref) {
        attempts++;
        return attempts == 1 ? request.future : Future.value(null);
      }),
    ]);
    expect(find.byType(RamisLoading), findsOneWidget);
    request.completeError(Exception('Sin conexión'));
    await tester.pumpAndSettle();
    expect(find.byType(RamisErrorView), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.byType(RamisEmptyState), findsOneWidget);
    expect(find.text('Empezar a Conducir'), findsOneWidget);
  });

  testWidgets('Botones y combustible admiten texto doble sin desbordar',
      (tester) async {
    var taps = 0;
    await _pump(
        tester,
        RamisScaffold(
            body: ListView(children: [
          RamisButton(
              label: 'Confirmar y Finalizar Jornada',
              icon: Icons.check,
              fullWidth: true,
              onPressed: () => taps++),
          RamisButton(
              label: 'Guardando documento',
              isLoading: true,
              onPressed: () => taps++),
          FuelGaugeSelector(value: 50, onChanged: (_) => taps++),
        ])),
        size: const Size(320, 640),
        scale: 2);
    await tester.pump();
    await tester.tap(find.text('Confirmar y Finalizar Jornada'));
    await tester.tap(find.text('3/4'));
    expect(taps, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Alta de vehículo conserva validación y acceso con teclado abierto',
      (tester) async {
    await _pump(
        tester,
        RamisScaffold(
            body: Builder(
                builder: (context) => RamisButton(
                    label: 'Nuevo vehículo',
                    onPressed: () => mostrarAltaVehiculo(context)))),
        scale: 1.5);
    await tester.tap(find.text('Nuevo vehículo'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Registrar vehículo'));
    await tester.tap(find.text('Registrar vehículo'));
    await tester.pumpAndSettle();
    expect(find.text('Ingrese la placa'), findsOneWidget);
    expect(find.text('Ingrese el nombre o modelo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
