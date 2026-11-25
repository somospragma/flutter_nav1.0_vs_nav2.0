import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'comparison.dart';
import 'demo_theme.dart';
import 'shared.dart';

void main() => runApp(const GoRouterDemoApp());

class GoRouterDemoApp extends StatefulWidget {
  const GoRouterDemoApp({super.key});

  @override
  State<GoRouterDemoApp> createState() => _GoRouterDemoAppState();
}

class _GoRouterDemoAppState extends State<GoRouterDemoApp> {
  final _session = ValueNotifier(false);

  // El árbol de GoRoute sustituye al parser, AppRoutePath y RouterDelegate manuales.
  late final _router = GoRouter(
    refreshListenable: _session,
    redirect: (context, state) {
      final path = state.uri.path;
      if (!_session.value &&
          (path == '/profile' || path == '/profile/orders')) {
        return Uri(
          path: '/login',
          queryParameters: {'redirect': path},
        ).toString();
      }
      if (_session.value && path == '/login') {
        final destination = state.uri.queryParameters['redirect'];
        if (_validReturnPath(destination)) return destination ?? '/';
      }
      return null;
    },
    errorBuilder: (context, state) => _notFound(context, state.uri),
    routes: [
      GoRoute(
        path: '/',
        builder: _home,
        routes: [
          GoRoute(
            path: 'products',
            builder: (context, state) => ProductsScreen(
              sort: state.uri.queryParameters['sort'],
              onSort: (sort) => context.go(
                Uri(
                  path: '/products',
                  queryParameters: {if (sort != null) 'sort': sort},
                ).toString(),
              ),
              onProduct: (id) =>
                  context.goNamed('product', pathParameters: {'id': id}),
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'product',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return CustomTransitionPage<void>(
                    key: state.pageKey,
                    child: kProducts.any((product) => product.id == id)
                        ? ProductDetailScreen(productId: id)
                        : _notFound(context, state.uri),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                  );
                },
              ),
            ],
          ),
          GoRoute(path: 'login', builder: _login),
          GoRoute(
            path: 'profile',
            builder: (context, state) => _profile(context, orders: false),
          ),
          GoRoute(
            path: 'profile/orders',
            builder: (context, state) => _profile(context, orders: true),
          ),
          GoRoute(
            path: 'links',
            builder: (context, state) =>
                DeepLinkGuide(onPreview: () => context.go('/products/42')),
          ),
          GoRoute(
            path: 'comparison',
            builder: (context, state) => const ComparisonScreen(),
          ),
        ],
      ),
    ],
  );

  bool _validReturnPath(String? path) =>
      path == null || path == '/profile' || path == '/profile/orders';

  Widget _home(BuildContext context, GoRouterState state) => DemoHome(
        title: 'go_router · Navigator 2.0',
        onProducts: () => context.go('/products'),
        actions: [
          ScenarioCard(
            number: '01',
            title: 'El mismo enlace, menos código',
            description: 'navdemo://app/products/42 sigue abriendo el detalle. '
                'go_router interpreta :id y crea la pila Inicio → Productos → Detalle '
                'a partir del árbol de GoRoute.',
            action: 'Cómo probar el enlace',
            onPressed: () => context.go('/links'),
          ),
          ScenarioCard(
            number: '02',
            title: 'Una redirección para proteger el perfil',
            description:
                'redirect comprueba la sesión. refreshListenable vuelve a '
                'evaluarlo cuando cambia: al iniciar sesión regresas al perfil solicitado.',
            action: 'Abrir mi perfil',
            onPressed: () => context.go('/profile'),
          ),
          ScenarioCard(
            number: '03',
            title: 'Un destino para los enlaces rotos',
            description:
                'errorBuilder muestra una pantalla de recuperación cuando '
                'ningún GoRoute coincide. Validar que un producto exista sigue siendo tarea nuestra.',
            action: 'Probar un enlace roto',
            onPressed: () => context.go('/no-existe'),
          ),
          TextButton(
            onPressed: () => context.go('/comparison'),
            child: const Text('Comparar las tres implementaciones'),
          ),
        ],
        explainer: const ExplainerPanel(
          title: '¿Qué nos ahorra go_router?',
          initiallyExpanded: true,
          lines: [
            'No es Navigator 3.0: es una abstracción sobre Router / Navigator 2.0.',
            '1. GoRoute(path: ...) reemplaza el parseo manual de segmentos y el modelo AppRoutePath de esta demo.',
            '2. Las rutas hijas construyen las páginas padre: no escribimos Navigator.pages ni onDidRemovePage.',
            '3. state.pathParameters y state.uri.queryParameters entregan los parámetros.',
            '4. redirect + refreshListenable coordinan el cambio de sesión y destino.',
            '5. MaterialApp.router(routerConfig: ...) conecta parser, delegate y botón atrás.',
            'context.go cambia a la pila configurada para un destino. context.push agrega una pantalla; context.pop vuelve y puede devolver un resultado.',
            'La consola muestra matches reales de go_router, no una pila calculada por la demo.',
            'Seguimos implementando pantallas, reglas de acceso, validación de productos y configuración Android/iOS de enlaces externos.',
          ],
        ),
      );

  Widget _login(BuildContext context, GoRouterState state) {
    final destination = state.uri.queryParameters['redirect'];
    if (!_validReturnPath(destination)) return _notFound(context, state.uri);
    return MessageScreen(
      title: 'Sesión de prueba',
      icon: Icons.lock_outline,
      children: [
        Text(
          destination == null
              ? 'Vamos a simular un inicio de sesión'
              : 'Querías abrir tu perfil',
        ),
        const SizedBox(height: 12),
        const Text(
          'Sin credenciales ni servidor. El botón cambia una variable; '
          'refreshListenable avisa a go_router y redirect elige el destino.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text('Después de continuar irás a: ${destination ?? '/'}'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => _session.value = true,
          child: const Text('Continuar con sesión de prueba'),
        ),
        TextButton(
          onPressed: () => context.go('/'),
          child: const Text('Cancelar y volver al inicio'),
        ),
      ],
    );
  }

  Widget _profile(
    BuildContext context, {
    required bool orders,
  }) =>
      MessageScreen(
        title: 'Perfil',
        icon: Icons.person,
        children: [
          Text(
            '¡Llegaste a tu perfil!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          const Text(
            'go_router evaluó nuestra regla de sesión antes de mostrar esta ruta. '
            'Las pestañas siguen siendo URLs; no son navegadores independientes.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'info', label: Text('Info')),
              ButtonSegment(value: 'orders', label: Text('Pedidos')),
            ],
            selected: {orders ? 'orders' : 'info'},
            onSelectionChanged: (tabs) => context
                .go(tabs.first == 'orders' ? '/profile/orders' : '/profile'),
          ),
          const SizedBox(height: 16),
          Text(orders ? 'Aquí van tus pedidos' : 'Datos de la cuenta'),
          const Text('La sesión de prueba se pierde al reiniciar la app.'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              context.go('/');
              _session.value = false;
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      );

  Widget _notFound(BuildContext context, Uri uri) => MessageScreen(
        title: 'Enlace no encontrado',
        icon: Icons.link_off,
        children: [
          Text(
            '404 · Esta pantalla no existe',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text('Enlace recibido: $uri', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          const Text(
            'No hay una ruta, producto o destino de retorno válido para este enlace. '
            'Nuestra pantalla de recuperación ofrece una salida.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Ir al inicio'),
          ),
        ],
      );

  @override
  void dispose() {
    _router.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'go_router · Navigator 2.0',
        theme: demoTheme,
        routerConfig: _router,
        builder: (context, child) => Column(
          children: [
            Expanded(child: child ?? const SizedBox.shrink()),
            ListenableBuilder(
              listenable: Listenable.merge([_router.routerDelegate, _session]),
              builder: (context, _) {
                final configuration =
                    _router.routerDelegate.currentConfiguration;
                return DebugFooter(
                  title: 'go_router · rutas reconocidas',
                  lines: [
                    'Ruta: ${configuration.uri}',
                    'matches: [${configuration.matches.map((match) => match.matchedLocation).join(', ')}]',
                    'Params: ${configuration.pathParameters}',
                    'Sesión: ${_session.value ? 'activa (de prueba)' : 'sin iniciar'}',
                    if (configuration.isError)
                      'Sin coincidencia → errorBuilder',
                  ],
                );
              },
            ),
          ],
        ),
      );
}
