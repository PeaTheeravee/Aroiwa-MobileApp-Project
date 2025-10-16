import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddRecipePage extends StatefulWidget {
  final Function(int) setPage;

  const AddRecipePage({super.key, required this.setPage});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  // Lists to hold the controllers for ingredients and methods
  List<Map<String, TextEditingController>> ingredients = [];
  List<TextEditingController> methodControllers = [];

  String _errorMessage = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Start with one ingredient
    addNewIngredient();
    // Start with one method
    addNewMethod();
  }

  void addNewIngredient() {
    ingredients.add({
      'ingredient': TextEditingController(),
      'unit': TextEditingController(),
    });
    setState(() {});
  }

  void removeIngredient(int index) {
    if (ingredients.length > 1) {
      ingredients.removeAt(index);
      setState(() {});
    }
  }

  void addNewMethod() {
    methodControllers.add(TextEditingController());
    setState(() {});
  }

  void removeMethod(int index) {
    if (methodControllers.length > 1) {
      methodControllers.removeAt(index);
      setState(() {});
    }
  }

  Future<void> submitRecipe() async {
    if (_formKey.currentState!.validate()) {
      final url = Uri.parse('http://localhost:8000/recipes/create');
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      final userId = prefs.getInt('user_id');

      final headers = {
        'Authorization': accessToken != null ? 'Bearer $accessToken' : '',
        'Content-Type': 'application/json',
      };

      final body = {
        'name': nameController.text,
        'ingredients': ingredients
            .map((entry) =>
                '${entry['ingredient']!.text}/-/${entry['unit']!.text}')
            .join('/*/'),
        'method':
            methodControllers.map((controller) => controller.text).join('/*/'),
        'imglink': imageUrlController.text,
        'user_id': userId, // ส่งเป็น int โดยตรง
      };

      print(body);

      setState(() {
        _isLoading = true;
        _errorMessage = ''; // Clear previous error message
      });

      try {
        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(
                  child: Text('เพิ่มสูตรอาหารสำเร็จ',
                      style:
                          TextStyle(color: Colors.brown[800], fontSize: 16))),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color.fromARGB(255, 255, 171, 45),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0), // ปรับมุมโค้ง
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Failed to create recipe. Please try again.';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage =
              'Unable to connect to the internet. Please try later.';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFCC80), // Background color
      appBar: AppBar(
        backgroundColor:
            const Color.fromARGB(255, 255, 171, 45), // AppBar color
        title: const Text('สร้างสูตรอาหาร'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 35),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อสูตรอาหาร',
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: Icon(Icons.fastfood, color: Colors.orange),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกชื่อสูตรอาหาร';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 15),
                // วัตถุดิบ
                const Text('วัตถุดิบ', style: TextStyle(fontSize: 18)),
                const SizedBox(
                  height: 5,
                ),
                Column(
                  children: List.generate(ingredients.length, (index) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: TextFormField(
                                controller: ingredients[index]['ingredient'],
                                decoration: const InputDecoration(
                                  labelText: 'วัตถุดิบ',
                                  fillColor: Colors.white,
                                  filled: true,
                                  prefixIcon:
                                      Icon(Icons.list, color: Colors.orange),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'กรุณากรอกวัตถุดิบ';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: ingredients[index]['unit'],
                                decoration: const InputDecoration(
                                  labelText: 'หน่วย',
                                  fillColor: Colors.white,
                                  filled: true,
                                  prefixIcon: Icon(Icons.assignment,
                                      color: Colors.orange),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'กรุณากรอกหน่วย';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            // const SizedBox(width: 2),
                            IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red, size: 20),
                              // padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              onPressed: () => removeIngredient(index),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        )
                      ],
                    );
                  }),
                ),
                TextButton(
                  onPressed: addNewIngredient,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: const Text(
                      '+ เพิ่มวัตถุดิบ',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // วิธีการ
                const Text('วิธีทำ', style: TextStyle(fontSize: 18)),
                const SizedBox(
                  height: 5,
                ),
                Column(
                  children: List.generate(methodControllers.length, (index) {
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: methodControllers[index],
                                decoration: const InputDecoration(
                                  labelText: 'วิธีทำ',
                                  fillColor: Colors.white,
                                  filled: true,
                                  prefixIcon:
                                      Icon(Icons.kitchen, color: Colors.orange),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'กรุณาระบุวิธีการปรุงอาหาร';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red, size: 20),
                              constraints: const BoxConstraints(),
                              onPressed: () => removeMethod(index),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        )
                      ],
                    );
                  }),
                ),
                TextButton(
                  onPressed: addNewMethod,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(25)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    child: const Text(
                      '+ เพิ่มวิธีการ',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: Icon(Icons.image, color: Colors.orange),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอก image URL';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 35),
                ElevatedButton(
                  onPressed: _isLoading ? null : submitRecipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 12.0,
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('สร้างสูตรอาหาร',
                          style: TextStyle(fontSize: 20, color: Colors.white)),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
