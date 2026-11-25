import 'package:flutter/material.dart';
import 'comparison.dart';
import 'demo_theme.dart';
import 'shared.dart';

void main() => runApp(const NavigatorTwoApp());

enum RouteKind {
  home,
  products,
  detail,
  login,
  profile,
  links,
  comparison,
  unknown,
}

/// El "estado de navegación": una descripción de DÓNDE estamos, no de CÓMO llegar.
@immutable
class AppRoutePath {
  const AppRoutePath._(
    this.kind, {
    this.productId,
    this.sort,
    this.tab = 'info',
    this.redirect,
    this.unknownPath,
  });
  const AppRoutePath.home() : this._(RouteKind.home);
  const AppRoutePath.products({String? sort})
      : this._(RouteKind.products, sort: sort);
  const AppRoutePath.detail(String id)
      : this._(RouteKind.detail, productId: id);
  const AppRoutePath.login({String? redirect})
      : this._(RouteKind.login, redirect: redirect);
  const AppRoutePath.profile({String tab = 'info'})
      : this._(RouteKind.profile, tab: tab);
  const AppRoutePath.links() : this._(RouteKind.links);
  const AppRoutePath.comparison() : this._(RouteKind.comparison);
  const AppRoutePath.unknown(String path)
      : this._(RouteKind.unknown, unknownPath: path);

  final RouteKind kind;
  final String? productId;
  final String? sort;
  final String tab;
  final String? redirect;
  final String? unknownPath;

  Uri get uri => switch (kind) {
        RouteKind.home => Uri(path: '/'),
        RouteKind.products => Uri(
            path: '/products',
            queryParameters: sort == null ? null : {'sort': sort!},
          ),
        RouteKind.detail => Uri(pathSegments: ['', 'products', productId!]),
        RouteKind.login => Uri(
            path: '/login',
            queryParameters: redirect == null ? null : {'redirect': redirect!},
          ),
        RouteKind.profile => Uri(
            path: tab == 'orders' ? '/profile/orders' : '/profile',
          ),
        RouteKind.links => Uri(path: '/links'),
        RouteKind.comparison => Uri(path: '/comparison'),
        RouteKind.unknown => Uri.parse(unknownPath!),
      };

  /// A dónde lleva "atrás" desde esta ruta.
  AppRoutePath get parent => switch (kind) {
        RouteKind.detail => const AppRoutePath.products(),
        _ => const AppRoutePath.home(),
      };

  /// Pila de páginas que representa esta ruta: Home → Productos → Detalle, etc.
  List<String> get stackKeys => switch (kind) {
        RouteKind.home => ['home'],
        RouteKind.products => ['home', 'products'],
        RouteKind.detail => ['home', 'products', 'product-$productId'],
        RouteKind.login => ['home', 'login'],
        RouteKind.profile => ['home', 'profile'],
        RouteKind.links => ['home', 'links'],
        RouteKind.comparison => ['home', 'comparison'],
        RouteKind.unknown => ['home', '404'],
      };

  @override
  bool operator ==(Object other) => other is AppRoutePath && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;
}

/// URL ⇄ AppRoutePath (en ambos sentidos).
class AppRouteInformationParser extends RouteInformationParser<AppRoutePath> {
  static AppRoutePath parse(Uri uri) {
    if (uri.hasScheme &&
        uri.scheme != 'http' &&
        uri.scheme != 'https' &&
        !(uri.scheme == 'navdemo' && uri.host == 'app')) {
      return AppRoutePath.unknown(uri.toString());
    }
    final s = uri.pathSegments;
    if (s.isEmpty) return const AppRoutePath.home();
    switch (s.first) {
      case 'products':
        if (s.length == 1) {
          final sort = uri.queryParameters['sort'];
          return AppRoutePath.products(
            sort: const ['price', 'name'].contains(sort) ? sort : null,
          );
        }
        if (s.length == 2 && kProducts.any((product) => product.id == s[1])) {
          return AppRoutePath.detail(s[1]);
        }
      case 'login':
        if (s.length == 1) {
          final redirect = uri.queryParameters['redirect'];
          if (redirect == null ||
              redirect == '/profile' ||
              redirect == '/profile/orders') {
            return AppRoutePath.login(redirect: redirect);
          }
        }
      case 'profile':
        if (s.length == 1) return const AppRoutePath.profile();
        if (s.length == 2 && s[1] == 'orders') {
          return const AppRoutePath.profile(tab: 'orders');
        }
      case 'links':
        if (s.length == 1) return const AppRoutePath.links();
      case 'comparison':
        if (s.length == 1) return const AppRoutePath.comparison();
    }
    return AppRoutePath.unknown(uri.toString());
  }

  @override
  Future<AppRoutePath> parseRouteInformation(
    RouteInformation routeInformation,
  ) async =>
      parse(routeInformation.uri);

  @override
  RouteInformation restoreRouteInformation(AppRoutePath configuration) =>
      RouteInformation(uri: configuration.uri);
}

/// Página con transición de fundido (ejemplo de transición personalizada).
class FadePage extends Page<void> {
  const FadePage({super.key, required this.child});
  final Widget child;

  @override
  Route<void> createRoute(BuildContext context) => PageRouteBuilder<void>(
        settings: this,
        pageBuilder: (_, __, ___) => child,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      );
}

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  AppRoutePath _path = const AppRoutePath.home();
  bool _loggedIn = false;

  bool get loggedIn => _loggedIn;

  @override
  AppRoutePath get currentConfiguration => _path;

  /// Guard: /profile exige sesión; si no, redirige a login recordando el destino.
  AppRoutePath _guard(AppRoutePath p) =>
      p.kind == RouteKind.profile && !_loggedIn
          ? AppRoutePath.login(redirect: p.uri.toString())
          : p;

  void go(AppRoutePath path) {
    _path = _guard(path);
    notifyListeners();
  }

  void logIn() {
    _loggedIn = true;
    final target = _path.redirect;
    // El destino original sale del query param, así funciona también con deep links.
    go(
      target == null
          ? const AppRoutePath.home()
          : AppRouteInformationParser.parse(Uri.parse(target)),
    );
  }

  void logOut() {
    _loggedIn = false;
    go(_path.kind == RouteKind.profile ? const AppRoutePath.home() : _path);
  }

  /// Se llama cuando el sistema/navegador entrega una URL nueva (deep link, recarga, atrás del navegador).
  /// No hace falta notifyListeners: el Router se reconstruye solo tras este Future.
  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    _path = _guard(configuration);
  }

  List<String> get stackKeys => _path.stackKeys;

  Widget _screenFor(String key) {
    switch (key) {
      case 'home':
        return DemoHome(
          title: 'Navigator 2.0 · Declarativo',
          onProducts: () => go(const AppRoutePath.products()),
          actions: [
            ScenarioCard(
              number: '01',
              title: 'Abrir desde un enlace externo',
              description:
                  'Un enlace en Chrome u otra app puede abrir directamente el producto 42, '
                  'incluso si esta app está cerrada. No es lo mismo que pulsar un botón aquí.',
              action: 'Cómo probar el enlace',
              onPressed: () => go(const AppRoutePath.links()),
            ),
            ScenarioCard(
              number: '02',
              title: 'Pedir sesión antes de entrar',
              description: _loggedIn
                  ? 'Ya tienes una sesión de prueba. Ahora puedes entrar al perfil directamente.'
                  : 'El perfil simula una pantalla privada. Primero verás un login de prueba; '
                      'al continuar llegarás al perfil que habías pedido, no al inicio.',
              action: 'Abrir mi perfil',
              onPressed: () => go(const AppRoutePath.profile()),
            ),
            ScenarioCard(
              number: '03',
              title: '¿Y si el enlace está equivocado?',
              description:
                  'Un enlace viejo o mal escrito puede apuntar a una pantalla que no existe. '
                  'El error 404 lo explica y permite volver al inicio en vez de dejar la app en blanco.',
              action: 'Probar un enlace roto',
              onPressed: () => go(const AppRoutePath.unknown('/no-existe')),
            ),
            TextButton(
              onPressed: () => go(const AppRoutePath.comparison()),
              child: const Text('Comparar Navigator 1.0 y 2.0'),
            ),
            if (_loggedIn)
              OutlinedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
                onPressed: logOut,
              ),
          ],
          explainer: const ExplainerPanel(
            title: '¿Cómo funciona Navigator 2.0?',
            initiallyExpanded: true,
            lines: [
              '1. URL / sistema → RouteInformationParser.parseRouteInformation → AppRoutePath (el estado).',
              '2. RouterDelegate.setNewRoutePath guarda ese estado (con guard de login).',
              '3. RouterDelegate.build convierte el estado en una LISTA de Page → Navigator(pages: ...).',
              '4. Si el usuario navega: se cambia el estado + notifyListeners → se reconstruye la lista de páginas.',
              '5. currentConfiguration → restoreRouteInformation → la URL del navegador se actualiza sola.',
              'Mira la consola: una ruta de detalle crea [home, products, product-42]. Atrás regresa a Productos y después al inicio.',
              'El guard de sesión y el 404 son decisiones de esta demo, no funciones exclusivas de Navigator 2.0.',
            ],
          ),
        );
      case 'products':
        return ProductsScreen(
          sort: _path.sort,
          onSort: (s) => go(AppRoutePath.products(sort: s)),
          onProduct: (id) => go(AppRoutePath.detail(id)),
        );
      case 'login':
        return MessageScreen(
          title: 'Sesión de prueba',
          icon: Icons.lock_outline,
          children: [
            Text(
              _path.redirect == null
                  ? 'Vamos a simular un inicio de sesión'
                  : 'Querías abrir tu perfil',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Esta pantalla no pide datos ni contacta un servidor. '
              'Solo cambia una variable de sesión para demostrar la redirección.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text('Después de continuar irás a: ${_path.redirect ?? '/'}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: logIn,
              child: const Text('Continuar con sesión de prueba'),
            ),
            TextButton(
              onPressed: () => go(const AppRoutePath.home()),
              child: const Text('Cancelar y volver al inicio'),
            ),
          ],
        );
      case 'profile':
        return MessageScreen(
          title: 'Perfil',
          icon: Icons.person,
          children: [
            const Text(
              '¡Llegaste a tu perfil!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'El Router recordó tu destino mientras iniciabas sesión. '
              'Ahora que la sesión está activa, volver a esta ruta ya no muestra el login.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'info', label: Text('Info')),
                ButtonSegment(value: 'orders', label: Text('Pedidos')),
              ],
              selected: {_path.tab},
              onSelectionChanged: (s) => go(AppRoutePath.profile(tab: s.first)),
            ),
            const SizedBox(height: 16),
            Text(
              _path.tab == 'orders'
                  ? 'Aquí van tus pedidos'
                  : 'Datos de la cuenta',
            ),
            const Text('La pestaña forma parte de la URL: /profile/orders'),
            const Text(
              'La sesión vive en memoria: se pierde al reiniciar la app.',
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: logOut,
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      case '404':
        return MessageScreen(
          title: 'Enlace no encontrado',
          icon: Icons.link_off,
          children: [
            const Text(
              '404 · Esta pantalla no existe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Enlace recibido: ${_path.unknownPath}',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'No es un fallo de la app: estamos mostrando qué ocurre con un enlace '
              'mal escrito, antiguo o un producto que no existe. '
              'El parser no encontró un destino válido y eligió esta pantalla de recuperación.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => go(const AppRoutePath.home()),
              child: const Text('Ir al inicio'),
            ),
          ],
        );
      case 'links':
        return DeepLinkGuide(
          onPreview: () => go(const AppRoutePath.detail('42')),
        );
      case 'comparison':
        return const ComparisonScreen();
      default:
        return ProductDetailScreen(productId: key.substring('product-'.length));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: Navigator(
              key: navigatorKey,
              pages: [
                for (final key in stackKeys)
                  key.startsWith('product-')
                      ? FadePage(key: ValueKey(key), child: _screenFor(key))
                      : MaterialPage<void>(
                          key: ValueKey(key),
                          child: _screenFor(key),
                        ),
              ],
              onDidRemovePage: (page) {
                // Ignora retiradas que ya están representadas por el nuevo estado.
                if (stackKeys.any((key) => page.key == ValueKey(key))) {
                  go(_path.parent);
                }
              },
            ),
          ),
          DebugFooter(
            title: 'Navigator 2.0 · estado → páginas',
            lines: [
              'Ruta: ${_path.uri}',
              'Estado: AppRoutePath.${_path.kind.name}',
              'Sesión: ${_loggedIn ? 'activa (de prueba)' : 'sin iniciar'}',
              'pages: [${stackKeys.join(', ')}]',
            ],
          ),
        ],
      );
}

class NavigatorTwoApp extends StatefulWidget {
  const NavigatorTwoApp({super.key});

  @override
  State<NavigatorTwoApp> createState() => _NavigatorTwoAppState();
}

class _NavigatorTwoAppState extends State<NavigatorTwoApp> {
  final AppRouterDelegate _delegate = AppRouterDelegate();
  final AppRouteInformationParser _parser = AppRouteInformationParser();

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Navigator 2.0',
        theme: demoTheme,
        routerDelegate: _delegate,
        routeInformationParser: _parser,
      );
}
