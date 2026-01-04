import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final double price;
  final int stock;
  final String imageName;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.stock,
    required this.imageName,
  });
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Map<String, dynamic>? user;
  bool loading = true;
  List<Product> products = [];

  @override
  void initState() {
    super.initState();
    _loadUser();
    fetchProducts();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString("user");

    if (userData != null) {
      setState(() {
        user = jsonDecode(userData);
      });
    }
    setState(() => loading = false);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    context.go('/login');
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse("https://mobilezoneproject.onrender.com/api/product"),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          products = data.map((item) {
            return Product(
              id: item['id'].toString(),
              name: item['name'],
              description: item['description'],
              category: item['category_name'] ?? item['category_id'].toString(),
              price: double.parse(item['price'].toString()),
              stock: int.parse(item['stock'].toString()),
              imageName: item['image'],
            );
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1CAAF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1CAAF),
        title: const Text(
          "Mobile Zone",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!loading)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: user == null
                  ? ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text("Login"),
                    )
                  : Row(
                      children: [
                        Text(
                          "Hi, ${user!['name']}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (user!['isAdmin'] == 1)
                          ElevatedButton(
                            onPressed: () => context.go('/admin'),
                            child: const Text("Admin"),
                          ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          onPressed: _logout,
                        ),
                      ],
                    ),
            ),
        ],
      ),

      // ================= GRID =================
      body: products.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.70,
              ),
              itemBuilder: (context, index) {
                final product = products[index];

                return Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IMAGE
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              "https://mobilezoneproject.onrender.com/uploads/${product.imageName}",
                              width: MediaQuery.of(context).size.width * 0.5,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported,
                                size: 60,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        Text(
                          product.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 4),

                        Text(
                          "Category: ${product.category}",
                          style: const TextStyle(fontSize: 12),
                        ),

                        Text(
                          "Stock: ${product.stock}",
                          style: TextStyle(
                            fontSize: 12,
                            color: product.stock > 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          "\$${product.price}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
