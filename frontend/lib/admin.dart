import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final int stock;
  final String? imageName; 

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.stock,
    this.imageName,
  });
}

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<Admin> createState() => _AdminState();
}

class _AdminState extends State<Admin> {
  List<Map<String, dynamic>> _categories = [];
  String? _selectedCategoryId;
  bool _loadingCategories = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  File? _pickedImage; 
  Uint8List? _webImage; 
  XFile? _imageFile; 

  List<Product> products = [];
  final String baseUrl =
      "https://mobilezoneproject.onrender.com"; 

  @override
  void initState() {
    super.initState();
    loadCategories();
    fetchProducts();
  }

  Future<void> loadCategories() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/category"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _categories = data
              .map(
                (e) => {"id": e['id'].toString(), "name": e['name'].toString()},
              )
              .toList();
          _loadingCategories = false;
        });
      }
    } catch (e) {
      setState(() => _loadingCategories = false);
      debugPrint("Error loading categories: $e");
    }
  }

  Future<void> fetchProducts() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/api/product"));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          products = data
              .map(
                (item) => Product(
                  id: item['id'].toString(),
                  name: item['name'],
                  description: item['description'],
                  price: double.parse(item['price'].toString()),
                  category: item['category_id'].toString(),
                  stock: item['stock'],
                  imageName: item['image'],
                ),
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching products: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
          _imageFile = pickedFile;
        });
      } else {
        setState(() {
          _pickedImage = File(pickedFile.path);
          _imageFile = pickedFile;
        });
      }
    }
  }

  Future<void> _addProduct() async {
    if (_formKey.currentState!.validate() &&
        _selectedCategoryId != null &&
        _imageFile != null) {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/api/addProduct"),
      );

      request.fields['name'] = _nameController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['price'] = _priceController.text;
      request.fields['stock'] = _stockController.text;
      request.fields['category_id'] = _selectedCategoryId!;


      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _webImage!,
            filename: 'upload.jpg',
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath('image', _pickedImage!.path),
        );
      }

      try {
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          _clearForm();
          fetchProducts(); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print("Error uploading: $e");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and pick image')),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _stockController.clear();
    setState(() {
      _pickedImage = null;
      _webImage = null;
      _imageFile = null;
    });
  }

  Future<void> _deleteProduct(String id) async {
    try {
      final response = await http.delete(Uri.parse("$baseUrl/api/product/$id"));
      if (response.statusCode == 200) {
        fetchProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Delete error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1CAAF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE1CAAF),
        title: const Text('Admin Panel'),
         leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Form Card
            Card(
              color: const Color(0xFFE1CAAF),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Product Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _loadingCategories
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              items: _categories
                                  .map(
                                    (c) => DropdownMenuItem<String>(
                                      value: c['id']
                                          .toString(),
                                      child: Text(c['name'].toString()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedCategoryId = v),
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                            ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Price'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Stock'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image),
                            label: const Text('Pick Image'),
                          ),
                          const SizedBox(width: 12),
                          if (_imageFile != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? Image.memory(
                                      _webImage!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      _pickedImage!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                            )
                          else
                            const Text('No image'),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _addProduct,
                        child: const Text('Add Product'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Table
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Image')),
                  DataColumn(label: Text('Action')),
                ],
                rows: products.map((product) {
                  return DataRow(
                    cells: [
                      DataCell(Text(product.name)),
                      DataCell(
                        product.imageName != null
                            ? Image.network(
                                "$baseUrl/uploads/${product.imageName}",
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Text('No image'),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(product.id),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
