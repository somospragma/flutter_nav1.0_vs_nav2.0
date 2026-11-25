import 'package:flutter/material.dart';

class ComparisonScreen extends StatelessWidget {
  const ComparisonScreen({super.key});

  static const _rows = [
    (
      'Modelo',
      'Imperativo: ordenas push/pop',
      'Declarativo: el estado define las páginas',
      'Navigator 2.0 con API de rutas',
    ),
    (
      'Fuente de verdad',
      'La pila interna del Navigator',
      'Tu estado (AppRoutePath)',
      'URI + coincidencias de GoRoute',
    ),
    (
      'URL en esta demo',
      'No sincronizada',
      'Sincronizada con el estado',
      'Gestionada por go_router',
    ),
    (
      'Deep links',
      'Posibles; debes gestionar las rutas',
      'URL → estado → lista de páginas',
      'GoRoute anidados + :id',
    ),
    (
      'Botón atrás',
      'Pop de la pila',
      'onDidRemovePage + estado',
      'Gestionado por go_router',
    ),
    (
      'Sesión en esta demo',
      'Login con comandos push',
      'Guard central en el delegate',
      'redirect + refreshListenable',
    ),
    (
      'Código de infraestructura',
      'Comandos push/pop',
      'Parser, delegate y páginas',
      'Árbol de GoRoute',
    ),
    (
      'Ideal para',
      'Flujos sencillos',
      'Aprender Router en detalle',
      'Routing declarativo sin boilerplate',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Comparativa')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('')),
                DataColumn(label: Text('Navigator 1.0')),
                DataColumn(label: Text('Navigator 2.0')),
                DataColumn(label: Text('go_router (sobre 2.0)')),
              ],
              rows: [
                for (final r in _rows)
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          r.$1,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(r.$2)),
                      DataCell(Text(r.$3)),
                      DataCell(Text(r.$4)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      );
}
