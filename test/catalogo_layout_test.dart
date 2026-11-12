import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_ocs/core/storage/session_storage.dart';
import 'package:sistema_ocs/core/theme/app_theme.dart';
import 'package:sistema_ocs/data/models/articulo_model.dart';
import 'package:sistema_ocs/features/almacen/articulos/articulo_provider.dart';
import 'package:sistema_ocs/features/almacen/articulos/articulos_list_screen.dart';

class CatalogoDemo extends ArticulosListNotifier {
  @override
  Future<List<ArticuloModel>> build() async => [
        ArticuloModel(
            id: 1,
            nombre: 'Llave Stillson 14 pulgadas',
            tipo: 'herramienta',
            stockActual: 10,
            unidadMedida: 'UND'),
        ArticuloModel(
            id: 2,
            nombre: 'Compresor industrial',
            tipo: 'equipo',
            stockActual: 0,
            unidadMedida: 'UND'),
      ];
}

void main() {
  for (final width in [320.0, 800.0]) {
    testWidgets('catálogo compacto y filtro funcional a $width px',
        (tester) async {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await const SessionStorage().write(key: 'user_role', value: 'admin');
      addTearDown(() => const SessionStorage().deleteAll());
      await tester.pumpWidget(ProviderScope(
        overrides: [articulosListProvider.overrideWith(CatalogoDemo.new)],
        child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: ArticulosListScreen(embedded: true))),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
          tester.getTopLeft(find.text('Llave Stillson 14 pulgadas')).dy -
              tester.getTopLeft(find.byType(TextField)).dy,
          lessThan(230),
          reason: 'El catálogo debe empezar sin una pared de filtros');
      await tester.tap(find.text('Tipo de producto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Herramienta'));
      await tester.pumpAndSettle();
      expect(find.text('1 resultados'), findsOneWidget);
      expect(find.text('Compresor industrial'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
