import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'demo_theme.dart';
import 'shared.dart';

void main() => runApp(const NavigatorOneApp());

/// Registra la pila de rutas. Es la única forma de "ver" la pila en Navigator 1.0:
/// la API imperativa no expone la lista de rutas.
class StackObserver extends NavigatorObserver {
  final List<Route<dynamic>> _routes = [];
  final ValueNotifier<List<String>> stack = ValueNotifier(const []);

  String _name(Route<dynamic> r) => r.settings.name ?? '(anónima)';

  void _publish() {
    final names = _routes.map(_name).toList();
    // Se difiere porque los callbacks pueden dispararse durante el build.
    SchedulerBinding.instance.addPostFrameCallback((_) => stack.value = names);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _publish();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _publish();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _publish();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = _routes.indexOf(oldRoute!);
    if (i >= 0 && newRoute != null) _routes[i] = newRoute;
    _publish();
  }
}

class NavigatorOneApp extends StatefulWidget {
  const NavigatorOneApp({super.key});

  @override
  State<NavigatorOneApp> createState() => _NavigatorOneAppState();
}

class _NavigatorOneAppState extends State<NavigatorOneApp> {
  final StackObserver _observer = StackObserver();
  final ValueNotifier<bool> _loggedIn = ValueNotifier(false);

  Route<dynamic> _onGenerateRoute(RouteSettings s) {
    Widget page;
    switch (s.name) {
      case '/':
        page = _Home(loggedIn: _loggedIn);
      case '/products':
        page = const _Products();
      case '/product':
        page = _Detail(productId: s.arguments as String);
      case '/checkout':
        page = _Checkout(productId: s.arguments as String);
      case '/login':
        page = _Auth(register: false, loggedIn: _loggedIn);
      case '/register':
        page = _Auth(register: true, loggedIn: _loggedIn);
      case '/limits':
        page = const _Limits();
      default:
        return MaterialPageRoute<void>(
          settings: s,
          builder: (context) => MessageScreen(
            title: 'Enlace no encontrado',
            icon: Icons.link_off,
            children: [
              Text('404 · No existe la ruta ${s.name}'),
              const SizedBox(height: 12),
              const Text(
                'Este ejemplo simula un enlace mal escrito. '
                'En vez de quedar en blanco, la app explica el error y ofrece una salida.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver a la pantalla anterior'),
              ),
            ],
          ),
        );
    }
    // El tipo de la ruta debe coincidir con el de pushNamed<T> para poder devolver resultados.
    if (s.name == '/checkout') {
      return MaterialPageRoute<bool>(settings: s, builder: (_) => page);
    }
    return MaterialPageRoute<dynamic>(settings: s, builder: (_) => page);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Navigator 1.0',
        theme: demoTheme,
        initialRoute: '/',
        onGenerateRoute: _onGenerateRoute,
        navigatorObservers: [_observer],
        builder: (context, child) => Column(
          children: [
            Expanded(child: child ?? const SizedBox.shrink()),
            ValueListenableBuilder<List<String>>(
              valueListenable: _observer.stack,
              builder: (_, stack, __) => DebugFooter(
                title: 'NavigatorObserver · pila (${stack.length})',
                lines: [
                  stack.isEmpty
                      ? '[]'
                      : stack.reversed.map((e) => '▸ $e').join('\n'),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Home extends StatelessWidget {
  const _Home({required this.loggedIn});
  final ValueNotifier<bool> loggedIn;

  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: loggedIn,
      builder: (_, isIn, __) => DemoHome(
        title: 'Navigator 1.0 · Imperativo',
        onProducts: () => nav.pushNamed('/products'),
        actions: [
          ScenarioCard(
            number: '01',
            title: 'Construir una pila con comandos',
            description:
                'Este botón ejecuta dos push: primero Productos y luego '
                'el detalle. Es navegación interna, NO un enlace externo.',
            action: 'Abrir producto 42 con dos push',
            onPressed: () {
              // Hay que empujar cada pantalla a mano para simular la pila completa.
              nav.pushNamed('/products');
              nav.pushNamed('/product', arguments: '42');
            },
          ),
          ScenarioCard(
            number: '02',
            title: 'Reemplazar y limpiar rutas',
            description: 'Login y Registro simulan un cambio de sesión. '
                'Observa cómo pushReplacement cambia la última ruta y '
                'pushAndRemoveUntil borra las anteriores.',
            action:
                isIn ? 'Cerrar sesión de prueba' : 'Iniciar sesión de prueba',
            onPressed: () =>
                isIn ? loggedIn.value = false : nav.pushNamed('/login'),
          ),
          ScenarioCard(
            number: '03',
            title: 'Recuperarse de un enlace roto',
            description: 'Si una ruta no existe, la app muestra un error 404 '
                'y una forma de volver. También se puede hacer con Navigator 1.0.',
            action: 'Probar un enlace roto',
            onPressed: () => nav.pushNamed('/foo'),
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.warning_amber),
            label: const Text('Limitaciones'),
            onPressed: () => nav.pushNamed('/limits'),
          ),
        ],
        explainer: const ExplainerPanel(
          title: '¿Cómo funciona Navigator 1.0?',
          initiallyExpanded: true,
          lines: [
            'Navigator es un widget con una PILA de rutas que tú modificas con comandos: push, pop, pushReplacement, pushAndRemoveUntil.',
            'No hay un estado central: la pila ES el estado y solo existe dentro del Navigator.',
            'Mira la barra negra inferior: un NavigatorObserver reporta cada cambio de la pila.',
            'El primer ejemplo empuja 2 pantallas con 2 llamadas; no es una prueba de enlace externo.',
          ],
        ),
      ),
    );
  }
}

class _Products extends StatelessWidget {
  const _Products();

  @override
  Widget build(BuildContext context) => ProductsScreen(
        onProduct: (id) =>
            Navigator.of(context).pushNamed('/product', arguments: id),
      );
}

class _Detail extends StatelessWidget {
  const _Detail({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context) => ProductDetailScreen(
        productId: productId,
        actions: [
          FilledButton.icon(
            icon: const Icon(Icons.payment),
            label: const Text('Comprar (espera un resultado)'),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              // push devuelve un Future con el valor del pop de la pantalla destino.
              final ok = await Navigator.of(
                context,
              ).pushNamed<bool>('/checkout', arguments: productId);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    ok == true
                        ? 'Compra confirmada'
                        : 'Compra cancelada (resultado: $ok)',
                  ),
                ),
              );
            },
          ),
        ],
      );
}

class _Checkout extends StatelessWidget {
  const _Checkout({required this.productId});
  final String productId;

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final nav = Navigator.of(context);
          final leave = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('¿Salir del pago?'),
              content: const Text('PopScope interceptó el botón atrás.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Quedarme'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Salir'),
                ),
              ],
            ),
          );
          if (leave == true) nav.pop(false);
        },
        child: MessageScreen(
          title: 'Checkout',
          icon: Icons.payment,
          children: [
            Text(
              'Pagar ${productById(productId).name}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            const Text('Intenta volver con atrás: se pedirá confirmación.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar (pop(true))'),
            ),
          ],
        ),
      );
}

class _Auth extends StatelessWidget {
  const _Auth({required this.register, required this.loggedIn});
  final bool register;
  final ValueNotifier<bool> loggedIn;

  @override
  Widget build(BuildContext context) {
    final nav = Navigator.of(context);
    return MessageScreen(
      title: register ? 'Registro' : 'Login',
      icon: register ? Icons.person_add : Icons.login,
      children: [
        FilledButton(
          onPressed: () {
            loggedIn.value = true;
            // Borra TODA la pila y deja solo Home.
            nav.pushNamedAndRemoveUntil('/', (_) => false);
          },
          child: Text(
            register
                ? 'Registrarme (pushNamedAndRemoveUntil)'
                : 'Entrar (pushNamedAndRemoveUntil)',
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () =>
              nav.pushReplacementNamed(register ? '/login' : '/register'),
          child: Text(
            register
                ? 'Ya tengo cuenta (pushReplacement)'
                : 'Crear cuenta (pushReplacement)',
          ),
        ),
        const ExplainerPanel(
          title: '¿Qué pasó en la pila?',
          initiallyExpanded: true,
          lines: [
            'pushReplacement cambia la ruta superior sin crecer la pila.',
            'pushAndRemoveUntil con (_) => false vacía la pila y deja solo la nueva ruta.',
          ],
        ),
      ],
    );
  }
}

class _Limits extends StatelessWidget {
  const _Limits();

  @override
  Widget build(BuildContext context) => const MessageScreen(
        title: 'Limitaciones de 1.0',
        icon: Icons.warning_amber,
        children: [
          ExplainerPanel(
            title: 'Lo que Navigator 1.0 no resuelve bien',
            initiallyExpanded: true,
            lines: [
              '• Navigator 1.0 SÍ puede recibir deep links; hay que traducirlos a rutas y construir la pila explícitamente.',
              '• Esta demo 1.0 solo muestra navegación interna y no sincroniza la URL en web.',
              '• La pila se modifica con comandos. Navigator 2.0 permite describirla como una lista de páginas derivada del estado.',
              '• La autenticación y el error 404 se pueden implementar en ambas versiones.',
              '• Para navegación sencilla, push y pop siguen siendo una opción válida.',
            ],
          ),
        ],
      );
}
