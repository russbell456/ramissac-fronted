import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/core/storage/session_storage.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/data/models/token_model.dart';
import 'package:sistema_ocs/data/services/auth_service.dart';
import 'package:sistema_ocs/features/dashboard/dashboard_screen.dart';
import 'package:sistema_ocs/features/login/auth_notifier.dart';
import 'package:sistema_ocs/features/login/login_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/models/rq_local_model.dart';
import 'package:sistema_ocs/features/rq_urgente/rq_list_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/rq_review_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/urgent_rq_screen.dart';
import 'package:sistema_ocs/features/rq_urgente/services/urgent_rq_service.dart';
import 'package:sistema_ocs/features/rq_urgente/widgets/rq_widgets.dart';
import 'package:sistema_ocs/main.dart';

class _Requests extends UrgentRQService {
  @override
  Future<Map<String, dynamic>> obtener(int id) async => {
        'id': id,
        'numero': 'RQ-010-2026',
        'estado': 'ENVIADO',
        'nombre_proyecto': 'Mantenimiento industrial',
        'items': [
          {
            'id': 1,
            'numero_item': 1,
            'nombre_producto': 'Tubo industrial',
            'cantidad': 2,
            'unidad_medida': 'M',
            'articulo_id': 2,
            'estado_gestion': 'PENDIENTE',
            'descripcion': 'Detalle técnico del tubo',
            'adjuntos': []
          }
        ],
      };
  @override
  Future<List<Map<String, dynamic>>> stock(int id) async => [
        {'numero_item': 1, 'stock_actual': 4, 'faltante': 0}
      ];
  @override
  Future<List<Map<String, dynamic>>> obrasActivas() async => [];
  @override
  Future<List<Map<String, dynamic>>> buscarProductos(String query) async => [
        {
          'id': 2,
          'nombre': 'Tubo de acero industrial con nombre largo',
          'unidad_medida': 'M',
          'stock_actual': 4
        }
      ];
  @override
  Future<List<Map<String, dynamic>>> listar() async => [
        {
          'id': 10,
          'numero': 'RQ-010-2026',
          'nombre_proyecto': 'Mantenimiento de un sistema de aire industrial',
          'estado': 'ENVIADO',
          'obra_codigo': '010-2026',
          'fecha_requerimiento': '2026-10-17',
          'items': [
            {'estado_gestion': 'POR_COMPRAR'}
          ],
        },
        {
          'id': 11,
          'numero': 'RQ-011-2026',
          'nombre_proyecto': 'Obra finalizada',
          'estado': 'FINALIZADO',
          'obra_codigo': '011-2026',
          'items': [],
        },
      ];
}

class _DelayedLogin extends AuthService {
  final result = Completer<TokenModel>();
  _DelayedLogin() : super(Dio());
  @override
  Future<TokenModel> login(String email, String password) => result.future;
}

Widget _app(Widget child, {double scale = 1}) => MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: child,
    );

void _viewport(WidgetTester tester, double width, {double height = 640}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

void main() {
  setUp(() => const SessionStorage().deleteAll());
  tearDown(() => const SessionStorage().deleteAll());

  for (final config in [
    (320.0, 1.0),
    (384.0, 1.1),
    (320.0, 1.6),
    (1024.0, 1.0)
  ]) {
    testWidgets('solicitudes, búsqueda y filtros: $config', (tester) async {
      _viewport(tester, config.$1);
      await const SessionStorage().write(key: 'user_role', value: 'admin');
      await tester.pumpWidget(_app(
          RQListScreen(
              service: _Requests(), loadDrafts: () async => <RQLocal>[]),
          scale: config.$2));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('2 requerimientos'), findsOneWidget);
      expect(tester.getTopLeft(find.text('RQ-010-2026')).dy, lessThan(240));
      await tester.ensureVisible(find.text('Enviados'));
      await tester.tap(find.text('Enviados'));
      await tester.pumpAndSettle();
      expect(find.text('1 requerimiento'), findsOneWidget);
      expect(find.text('Obra finalizada'), findsNothing);
      await tester.ensureVisible(find.text('Todos'));
      await tester.tap(find.text('Todos'));
      await tester.enterText(find.byType(TextField), 'finalizada');
      await tester.pumpAndSettle();
      expect(find.text('1 requerimiento'), findsOneWidget);
      await tester.tap(find.byTooltip('Limpiar búsqueda'));
      await tester.pumpAndSettle();
      expect(find.text('2 requerimientos'), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 1.6]) {
    testWidgets('login compacto, validación y contraseña visible: $scale',
        (tester) async {
      _viewport(tester, 320);
      await tester.pumpWidget(
          ProviderScope(child: _app(const LoginScreen(), scale: scale)));
      await tester.pumpAndSettle();
      final signIn = find.widgetWithText(FilledButton, 'Iniciar sesión');
      await tester.ensureVisible(signIn);
      await tester.tap(signIn);
      await tester.pumpAndSettle();
      expect(find.text('Ingresa un correo válido'), findsOneWidget);
      expect(find.text('Ingresa tu contraseña'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Mostrar contraseña'));
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('el login conserva campos y muestra errores durante la petición',
      (tester) async {
    final auth = _DelayedLogin();
    await tester.pumpWidget(ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(auth)],
        child: const OCSApp()));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'incorrecta');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    auth.result.completeError(Exception('Sin conexión'));
    await tester.pumpAndSettle();
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.textContaining('No se pudo iniciar sesión'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('acciones del pie no desbordan con letras grandes',
      (tester) async {
    _viewport(tester, 320);
    await tester.pumpWidget(_app(
        Scaffold(
            bottomNavigationBar: RqFooter(
                label: 'Firmar y enviar',
                secondary: const Text('25 productos'),
                onPressed: () {})),
        scale: 1.6));
    expect(tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('catálogo del formulario soporta teclado y letras grandes',
      (tester) async {
    _viewport(tester, 320);
    await tester
        .pumpWidget(_app(UrgentRQScreen(service: _Requests()), scale: 1.6));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Buscar en catálogo'));
    await tester.tap(find.text('Buscar en catálogo'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Cerrar catálogo'));
    await tester.pumpAndSettle();
  });

  testWidgets('pantallas amplias usan navegación lateral', (tester) async {
    _viewport(tester, 1024);
    await const SessionStorage().write(key: 'user_role', value: 'admin');
    await tester
        .pumpWidget(ProviderScope(child: _app(const DashboardScreen())));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('acceso con objetivos táctiles accesibles y contraste',
      (tester) async {
    _viewport(tester, 384, height: 900);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(ProviderScope(child: _app(const LoginScreen())));
    await tester.pumpAndSettle();
    try {
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    } finally {
      semantics.dispose();
    }
  });

  for (final scale in [1.0, 1.6]) {
    testWidgets('detalle compacto conserva información al desplegar: $scale',
        (tester) async {
      _viewport(tester, 320);
      await const SessionStorage().write(key: 'user_role', value: 'admin');
      await tester.pumpWidget(_app(
          RqReviewScreen(servidorId: 10, service: _Requests()),
          scale: scale));
      await tester.pumpAndSettle();
      expect(find.text('2 M'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Detalle técnico del tubo'), findsNothing);
      await tester.tap(find.text('1. Tubo industrial'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle técnico del tubo'), findsOneWidget);
      expect(find.byTooltip('Actualizar seguimiento'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final role in ['admin', 'trabajador', 'compras']) {
    testWidgets('navegación principal respeta el rol $role', (tester) async {
      _viewport(tester, 320);
      await const SessionStorage().write(key: 'user_role', value: role);
      await tester.pumpWidget(
          ProviderScope(child: _app(const DashboardScreen(), scale: 1.3)));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .destinations
              .length,
          role == 'trabajador' ? 3 : 4);
      expect(tester.takeException(), isNull);
    });
  }
}
