import 'package:flutter/material.dart';
import 'package:flutter_navigation_demo/main_nav1.dart';
import 'package:flutter_navigation_demo/main_nav2.dart';
import 'package:flutter_navigation_demo/main_nav3.dart';
import 'package:flutter_navigation_demo/shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> tapVisible(WidgetTester tester, String label) async {
    final target = find.text(label);
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  group('Nav 2.0 parser', () {
    test('round-trip de URLs válidas', () {
      for (final url in [
        '/',
        '/products',
        '/products?sort=price',
        '/products/42',
        '/profile/orders',
      ]) {
        final path = AppRouteInformationParser.parse(Uri.parse(url));
        expect(path.uri.toString(), url);
      }
    });

    test('ruta desconocida y sort inválido', () {
      expect(
        AppRouteInformationParser.parse(Uri.parse('/foo')).kind,
        RouteKind.unknown,
      );
      expect(
        AppRouteInformationParser.parse(Uri.parse('/products?sort=x')).sort,
        isNull,
      );
    });

    test('enlaces Android y productos inexistentes', () {
      expect(
        AppRouteInformationParser.parse(Uri.parse('navdemo://app/products/42')),
        const AppRoutePath.detail('42'),
      );
      for (final url in [
        'navdemo://otro/products/42',
        'navdemo://app/products/999',
        '/products/42/extra',
        '/login?redirect=https://example.com',
      ]) {
        expect(
          AppRouteInformationParser.parse(Uri.parse(url)).kind,
          RouteKind.unknown,
          reason: url,
        );
      }
      final path = AppRouteInformationParser.parse(
        Uri.parse('/no-existe?from=email'),
      );
      expect(path.uri.toString(), '/no-existe?from=email');
    });
  });

  group('Nav 2.0 delegate', () {
    testWidgets('enlace externo con app cerrada crea detalle y pila', (
      tester,
    ) async {
      tester.binding.platformDispatcher.defaultRouteNameTestValue =
          'navdemo://app/products/42';
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );
      await tester.pumpWidget(const NavigatorTwoApp());
      await tester.pumpAndSettle();
      expect(find.text('Detalle del producto 42'), findsOneWidget);
      expect(
        find.textContaining('[home, products, product-42]'),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Selecciona un producto'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Ver productos'), findsOneWidget);
    });

    testWidgets('enlaces externos actualizan app abierta y consola', (
      tester,
    ) async {
      await tester.pumpWidget(const NavigatorTwoApp());
      await tester.pumpAndSettle();
      await tester.binding.handlePushRoute('navdemo://app/products/77');
      await tester.pumpAndSettle();
      expect(find.text('Detalle del producto 77'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DebugFooter),
          matching: find.textContaining('Ruta: /products/77'),
        ),
        findsOneWidget,
      );

      await tester.binding.handlePushRoute(
        'navdemo://app/no-existe?from=email',
      );
      await tester.pumpAndSettle();
      expect(find.text('404 · Esta pantalla no existe'), findsOneWidget);
      expect(
        find.textContaining('Ruta: navdemo://app/no-existe?from=email'),
        findsOneWidget,
      );
      await tapVisible(tester, 'Ir al inicio');
      expect(find.text('Ver productos'), findsOneWidget);
    });

    testWidgets(
      'perfil explica login, recuerda destino y permite cerrar sesión',
      (tester) async {
        await tester.pumpWidget(const NavigatorTwoApp());
        await tester.pumpAndSettle();
        await tapVisible(tester, 'Abrir mi perfil');
        expect(find.text('Querías abrir tu perfil'), findsOneWidget);
        expect(
          find.text('Después de continuar irás a: /profile'),
          findsOneWidget,
        );

        await tapVisible(tester, 'Continuar con sesión de prueba');
        expect(find.text('Datos de la cuenta'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tapVisible(tester, 'Abrir mi perfil');
        expect(find.text('Querías abrir tu perfil'), findsNothing);
        await tapVisible(tester, 'Cerrar sesión');
        await tapVisible(tester, 'Abrir mi perfil');
        expect(find.text('Querías abrir tu perfil'), findsOneWidget);
        await tapVisible(tester, 'Cancelar y volver al inicio');
        expect(find.text('Ver productos'), findsOneWidget);
      },
    );

    testWidgets('enlace protegido recuerda también la pestaña Pedidos', (
      tester,
    ) async {
      await tester.pumpWidget(const NavigatorTwoApp());
      await tester.pumpAndSettle();
      await tester.binding.handlePushRoute('navdemo://app/profile/orders');
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Continuar con sesión de prueba');
      expect(find.text('Aquí van tus pedidos'), findsOneWidget);
      expect(find.textContaining('Ruta: /profile/orders'), findsOneWidget);
    });

    testWidgets('guía de enlace y consola caben en un teléfono pequeño', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(const NavigatorTwoApp());
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Cómo probar el enlace');
      await tapVisible(tester, 'Ver destino (solo navegación interna)');
      expect(find.text('Detalle del producto 42'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('go_router', () {
    testWidgets('enlace en frío construye padres y Atrás los recorre', (
      tester,
    ) async {
      tester.binding.platformDispatcher.defaultRouteNameTestValue =
          'navdemo://app/products/42';
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );
      await tester.pumpWidget(const GoRouterDemoApp());
      await tester.pumpAndSettle();
      expect(find.text('Detalle del producto 42'), findsOneWidget);
      expect(
        find.textContaining('matches: [/, /products, /products/42]'),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Selecciona un producto'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Ver productos'), findsOneWidget);
    });

    testWidgets('query params ordenan productos y goNamed abre el id', (
      tester,
    ) async {
      await tester.pumpWidget(const GoRouterDemoApp());
      await tester.pumpAndSettle();
      await tester.binding.handlePushRoute('navdemo://app/products?sort=price');
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Producto 77')).dy,
        lessThan(tester.getTopLeft(find.text('Producto 42')).dy),
      );
      await tapVisible(tester, 'Por nombre');
      expect(find.textContaining('sort=name'), findsOneWidget);
      await tapVisible(tester, 'Producto 42');
      expect(find.text('Detalle del producto 42'), findsOneWidget);
      expect(find.textContaining('Params: {id: 42}'), findsOneWidget);
    });

    testWidgets('refreshListenable redirige al destino protegido tras login', (
      tester,
    ) async {
      await tester.pumpWidget(const GoRouterDemoApp());
      await tester.pumpAndSettle();
      await tester.binding.handlePushRoute('navdemo://app/profile/orders');
      await tester.pumpAndSettle();
      expect(
        find.text('Después de continuar irás a: /profile/orders'),
        findsOneWidget,
      );
      expect(find.text('Aquí van tus pedidos'), findsNothing);
      await tapVisible(tester, 'Continuar con sesión de prueba');
      expect(find.text('Aquí van tus pedidos'), findsOneWidget);
      await tapVisible(tester, 'Info');
      expect(find.text('Datos de la cuenta'), findsOneWidget);
      await tapVisible(tester, 'Cerrar sesión');
      await tapVisible(tester, 'Abrir mi perfil');
      expect(find.text('Continuar con sesión de prueba'), findsOneWidget);
      await tapVisible(tester, 'Cancelar y volver al inicio');
      expect(find.text('Ver productos'), findsOneWidget);
    });

    testWidgets('errorBuilder y validación de producto permiten recuperarse', (
      tester,
    ) async {
      await tester.pumpWidget(const GoRouterDemoApp());
      await tester.pumpAndSettle();
      for (final url in [
        'navdemo://app/no-existe',
        'navdemo://app/products/999',
        '/login?redirect=https://example.com',
      ]) {
        await tester.binding.handlePushRoute(url);
        await tester.pumpAndSettle();
        expect(
          find.text('404 · Esta pantalla no existe'),
          findsOneWidget,
          reason: url,
        );
        expect(find.text('Continuar con sesión de prueba'), findsNothing);
        await tapVisible(tester, 'Ir al inicio');
        expect(find.text('Ver productos'), findsOneWidget);
      }
    });
  });

  group('Nav 1.0', () {
    testWidgets('enlace roto explica el error y permite volver', (
      tester,
    ) async {
      await tester.pumpWidget(const NavigatorOneApp());
      await tester.pumpAndSettle();
      await tapVisible(tester, 'Probar un enlace roto');
      expect(find.text('404 · No existe la ruta /foo'), findsOneWidget);
      await tapVisible(tester, 'Volver a la pantalla anterior');
      expect(find.text('Ver productos'), findsOneWidget);
    });

    testWidgets('pop devuelve resultado y PopScope pide confirmación', (
      tester,
    ) async {
      await tester.pumpWidget(const NavigatorOneApp());
      await tester.tap(find.text('Ver productos'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Producto 42'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Comprar'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('¿Salir del pago?'), findsOneWidget);
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Compra cancelada (resultado: false)'),
        findsOneWidget,
      );
    });
  });
}
