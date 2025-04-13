// 📁 lib/screens/catalogo_screen.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:provider/provider.dart'; // 🟢 Para usar Provider.of
import '../providers/cart_provider.dart';
import '../models/product.dart'; // 🟢 Para usar la clase Product correctamente

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  List productos = [];
  String searchQuery = "";
  String selectedCategory = "Todos";
  bool sortByPriceAsc = true;

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  Future<void> cargarProductos() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('http://192.168.0.12:5000/catalogo');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          productos = data['productos'];
        });
      } else {
        print("❌ Error HTTP: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error de red: $e");
    }
  }

  List<String> get categories {
    return [
      'Todos',
      ...{for (var p in productos) p['categoria'] ?? ''}
    ];
  }

  @override
  Widget build(BuildContext context) {
    List filtered = productos
        .where((p) =>
            (selectedCategory == 'Todos' ||
                p['categoria'] == selectedCategory) &&
            p['nombre'].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    filtered.sort((a, b) => sortByPriceAsc
        ? a['precio'].compareTo(b['precio'])
        : b['precio'].compareTo(a['precio']));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Catálogo de Productos"),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.mic),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) => setState(() => searchQuery = value),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCategory,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedCategory = value;
                            });
                          }
                        },
                        items: categories
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: Icon(sortByPriceAsc
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                      tooltip: 'Ordenar por precio',
                      onPressed: () =>
                          setState(() => sortByPriceAsc = !sortByPriceAsc),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final p = filtered[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Image.network(
                            p['imagen'] != null
                                ? "http://192.168.0.12:5000/uploads/${p['imagen']}"
                                : "",
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p['nombre'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Categoría: ${p['categoria']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bs ${p['precio'].toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF43A047), // verde personalizado
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            icon: const Icon(Icons.add_shopping_cart),
                            onPressed: () {
                              final cart = Provider.of<CartProvider>(context,
                                  listen: false);
                              cart.addToCart(
                                Product(
                                  id: p['id'],
                                  nombre: p['nombre'],
                                  descripcion: p['descripcion'],
                                  precio: p['precio'].toDouble(),
                                  stock: p['stock'],
                                  categoria: p['categoria'],
                                  imagen: p['imagen'],
                                ),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Producto agregado al carrito'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
