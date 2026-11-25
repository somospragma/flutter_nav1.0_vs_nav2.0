import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'demo_theme.dart';

@immutable
class Product {
  const Product(this.id, this.name, this.price);
  final String id;
  final String name;
  final double price;
}

const kProducts = [
  Product('42', 'Producto 42', 29.9),
  Product('77', 'Producto 77', 15.5),
  Product('101', 'Producto 101', 49.0),
];

Product productById(String id) => kProducts.firstWhere(
      (p) => p.id == id,
      orElse: () => Product(id, 'Producto $id', 0),
    );

/// Tarjeta expandible "¿Qué está pasando?" para explicar el concepto en vivo.
class ExplainerPanel extends StatelessWidget {
  const ExplainerPanel({
    super.key,
    required this.title,
    required this.lines,
    this.initiallyExpanded = false,
  });
  final String title;
  final List<String> lines;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ExpansionTile(
          leading: const Icon(Icons.lightbulb_outline),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          initiallyExpanded: initiallyExpanded,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in lines)
              Padding(
                  padding: const EdgeInsets.only(bottom: 6), child: Text(l)),
          ],
        ),
      );
}

/// Barra inferior con el estado interno de la navegación (pila, URL, etc.).
class DebugFooter extends StatefulWidget {
  const DebugFooter({super.key, required this.title, required this.lines});
  final String title;
  final List<String> lines;

  @override
  State<DebugFooter> createState() => _DebugFooterState();
}

class _DebugFooterState extends State<DebugFooter> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) => Material(
        color: demoInk,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  dense: true,
                  title: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(
                    _expanded ? Icons.expand_more : Icons.expand_less,
                    color: Colors.white,
                  ),
                  onTap: () => setState(() => _expanded = !_expanded),
                  subtitle: const Text(
                    'Consola en vivo · toca para plegar',
                    style: TextStyle(color: Color(0xFFD8BCFF), fontSize: 13),
                  ),
                ),
                if (_expanded)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          widget.lines.join('\n'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 18,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class ScenarioCard extends StatelessWidget {
  const ScenarioCard({
    super.key,
    required this.number,
    required this.title,
    required this.description,
    required this.action,
    required this.onPressed,
  });

  final String number;
  final String title;
  final String description;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'EJEMPLO $number',
                style: const TextStyle(
                  color: demoViolet,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(description),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child:
                    OutlinedButton(onPressed: onPressed, child: Text(action)),
              ),
            ],
          ),
        ),
      );
}

class DeepLinkGuide extends StatelessWidget {
  const DeepLinkGuide({super.key, required this.onPreview});
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) => MessageScreen(
        title: 'Un enlace, una pantalla',
        icon: Icons.open_in_new,
        children: [
          Text(
            'Desde fuera de la app',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            'Un deep link es una dirección que abre una pantalla concreta. '
            'Android reconoce navdemo://app y entrega la dirección al Router.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const SelectableText(
            'navdemo://app/products/42',
            style: TextStyle(color: demoViolet, fontWeight: FontWeight.w600),
          ),
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copiar enlace'),
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(text: 'navdemo://app/products/42'),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Enlace copiado. Ábrelo desde una app compatible.'),
                ),
              );
            },
          ),
          const ExplainerPanel(
            title: 'Prueba real en el emulador Android',
            initiallyExpanded: true,
            lines: [
              '1. Instala main.dart, main_nav2.dart o main_nav3.dart.',
              '2. En tu equipo ejecuta: python3 -m http.server 8000 --bind 127.0.0.1 --directory web',
              '3. Abre Chrome EN EL EMULADOR y entra a http://10.0.2.2:8000/deep-links.html.',
              '4. Pulsa “Abrir producto 42”. Android abrirá esta app directamente en el detalle.',
              '5. Repite con la app cerrada y luego abierta. Atrás debe llevar a Productos.',
              'Pegar el texto en cualquier lugar no lo abre automáticamente. Algunas apps no convierten los esquemas personalizados en enlaces: usa la página de prueba.',
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onPreview,
            child: const Text('Ver destino (solo navegación interna)'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Este último botón NO prueba un enlace externo. En web, usa '
            '/#/products/42 con el host y puerto donde corre Flutter.',
            textAlign: TextAlign.center,
          ),
        ],
      );
}

class DemoHome extends StatelessWidget {
  const DemoHome({
    super.key,
    required this.title,
    required this.onProducts,
    this.actions = const [],
    this.explainer,
  });
  final String title;
  final VoidCallback onProducts;
  final List<Widget> actions;
  final Widget? explainer;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: demoViolet,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NAVIGATION LAB',
                          style:
                              TextStyle(color: Colors.white, letterSpacing: 2),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Una ruta.\nDiferentes formas de llegar.',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 28,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Explora los ejemplos y observa la consola.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onProducts,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Ver productos'),
                  ),
                  const SizedBox(height: 8),
                  ...actions,
                  if (explainer != null) ...[
                    const SizedBox(height: 16),
                    explainer!,
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({
    super.key,
    required this.onProduct,
    this.sort,
    this.onSort,
  });
  final ValueChanged<String> onProduct;

  /// `null` = sin orden. Si [onSort] es null, no se muestran los filtros.
  final String? sort;
  final ValueChanged<String?>? onSort;

  @override
  Widget build(BuildContext context) {
    final items = [...kProducts];
    if (sort == 'price') items.sort((a, b) => a.price.compareTo(b.price));
    if (sort == 'name') items.sort((a, b) => a.name.compareTo(b.name));
    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Selecciona un producto',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (onSort != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  for (final s in const ['price', 'name'])
                    ChoiceChip(
                      label: Text(s == 'price' ? 'Por precio' : 'Por nombre'),
                      selected: sort == s,
                      onSelected: (on) => onSort!(on ? s : null),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          for (final p in items)
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.shopping_bag_outlined),
                ),
                title: Text(p.name),
                subtitle: Text(
                  '\$${p.price.toStringAsFixed(2)} · /products/${p.id}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onProduct(p.id),
              ),
            ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.actions = const [],
  });
  final String productId;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final p = productById(productId);
    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_bag, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    'Detalle del producto $productId',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 8),
                  Text('Precio: \$${p.price.toStringAsFixed(2)}'),
                  Text('Ruta: /products/$productId'),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...actions,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pantalla simple con título, mensaje y botones (login, 404, límites, etc.).
class MessageScreen extends StatelessWidget {
  const MessageScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 64),
                  const SizedBox(height: 16),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      );
}
