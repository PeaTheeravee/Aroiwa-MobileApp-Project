import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:aroiwa/view/recipe_detail_page.dart';

class RecipesListPage extends StatefulWidget {
  final Function(int) setPage;
  final Function(int) setRecipeId;

  const RecipesListPage(
      {super.key, required this.setPage, required this.setRecipeId});

  @override
  State<RecipesListPage> createState() => _RecipesListPageState();
}

class _RecipesListPageState extends State<RecipesListPage> {
  List recipes = [];
  List filteredRecipes = [];
  List<String> ingredientHave = [];
  List ingredientHaveList = [];

  String searchNameQuery = '';
  String searchIngredientQuery = '';

  double recipeScore = 0.0;

  TextEditingController ingredientController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRecipes();
  }

  Future<void> fetchRecipes() async {
    final url = Uri.parse('http://localhost:8000/recipes/all');
    print('this is : $url');
    final response = await http.get(url);

    print('this is : $response');

    if (response.statusCode == 200) {
      setState(() {
        recipes = List.from(
            json.decode(utf8.decode(response.bodyBytes))['recipes'].reversed);
        filteredRecipes = recipes;
        ingredientHaveList = recipes;
      });
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  void filterRecipesName(String query) {
    List filteredList = ingredientHaveList.where((recipe) {
      return recipe['name'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      searchNameQuery = query;
      filteredRecipes = filteredList;
    });
  }

  void filterRecipesNameRefresh(String query) {
    List filteredList = recipes.where((recipe) {
      return recipe['name'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      searchNameQuery = query;
      filteredRecipes = filteredList;
    });
  }

  Future<String> fetchScore(int recipeId) async {
    final url = Uri.parse('http://localhost:8000/scores/$recipeId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      print(json.decode(utf8.decode(response.bodyBytes)));
      return json
          .decode(utf8.decode(response.bodyBytes))['avg_score']
          .toString();
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  Future<Map<String, dynamic>> fetchScoreSort(int recipeId) async {
    final url = Uri.parse('http://localhost:8000/scores/$recipeId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decodedResponse = json.decode(utf8.decode(response.bodyBytes));
      print(decodedResponse); // แสดงค่าที่ได้จาก API

      // คืนค่าทั้งค่าเฉลี่ยและจำนวนคะแนน
      return {
        'avg_score': decodedResponse['avg_score'].toString(),
        'count': decodedResponse['count']
      };
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  void filterRecipesIngredient(List<String> ingredientsFocus) {
    
    print(searchController.text);

    filterRecipesNameRefresh(searchController.text);

    List filteredList = filteredRecipes.where((recipe) {
      List<String> ingredientsRef =
          recipe['ingredients'].toString().split('/*/');

      List<String> ingredientsUse = [];

      for (var ingredient in ingredientsRef) {
        // แยกค่าโดยใช้ '/-/'
        List<String> parts = ingredient.split('/-/');

        // ตรวจสอบว่ามีค่า 2 ค่าใน parts หรือไม่
        ingredientsUse.add(parts[0]);
      }

      return ingredientsFocus
          .every((ingredients) => ingredientsUse.contains(ingredients));

      // return ingredientsFocus.every((ingredient) =>
      //     ingredientsUse.any((use) => use.contains(ingredient)));
    }).toList();

    setState(() {
      ingredientHaveList = filteredList;
      filteredRecipes = filteredList;
    });
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(
              child: Text(
            'เรียงลำดับจาก',
            style: TextStyle(fontWeight: FontWeight.bold),
          )),
          backgroundColor: const Color(0xFFF9CE8A),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Center(
                    child: Text('คะแนนสูงสุด', style: TextStyle(fontSize: 19))),
                onTap: () {
                  sortRecipesByScore();
                  Navigator.pop(context); // ปิดป๊อปอัปเมื่อเลือกแล้ว
                },
              ),
              ListTile(
                title: const Center(
                    child: Text('ใหม่สุด', style: TextStyle(fontSize: 19))),
                onTap: () {
                  sortRecipesByNewest();
                  Navigator.pop(context); // ปิดป๊อปอัปเมื่อเลือกแล้ว
                },
              ),
              ListTile(
                title: const Center(
                    child: Text('เก่าสุด', style: TextStyle(fontSize: 19))),
                onTap: () {
                  sortRecipesByOldest();
                  Navigator.pop(context); // ปิดป๊อปอัปเมื่อเลือกแล้ว
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void sortRecipesByNewest() {
    setState(() {
      filteredRecipes.sort((a, b) => b['id'].compareTo(a['id']));
    });
  }

  Future<void> sortRecipesByOldest() async {
    setState(() {
      filteredRecipes.sort((a, b) => a['id'].compareTo(b['id']));
    });
  }

  Future<void> sortRecipesByScore() async {
    for (var recipe in recipes) {
      final score = await fetchScoreSort(recipe['id']);

      // แปลงค่า avg_score เป็น double และ count ให้ใช้ค่าเดิมหากเป็น int
      recipe['score'] =
          double.parse(score['avg_score']); // avg_score เป็น String จึงต้องแปลง
      recipe['score_count'] =
          score['count']; // ถ้า count เป็น int อยู่แล้ว ไม่ต้องแปลง
    }

    setState(() {
      // เรียงรายการอาหารจากจำนวนคะแนนและคะแนนมากไปน้อย
      filteredRecipes
          .sort((a, b) => b['score_count'].compareTo(a['score_count']));
      filteredRecipes.sort((a, b) => b['score'].compareTo(a['score']));
    });
  }

  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9CE8A),
      appBar: AppBar(
        title: Center(
            child: Image.asset(
          'assets/images/aroiwa-logo.png',
          width: 100,
          height: 100,
        )),
        backgroundColor: const Color(0xFFF9CE8A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: 'ค้นหาสูตรอาหาร',
                          border: InputBorder.none,
                          icon: Icon(Icons.search),
                        ),
                        onChanged: (query) => filterRecipesName(query),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      _showSortOptions();
                    },
                    icon: const Icon(Icons.sort_rounded),
                    color: Colors.brown[800],
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                        height: 50,
                        margin:
                            const EdgeInsets.only(left: 16, top: 5, bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: ingredientController,
                          decoration: const InputDecoration(
                            hintText: 'วัตถุดิบที่มี',
                            border: InputBorder.none,
                            icon: Icon(Icons.search),
                          ),
                        )),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        ingredientHave.add(ingredientController.text);
                        filterRecipesIngredient(ingredientHave);
                      });
                    },
                    icon: const Icon(Icons.add),
                    color: Colors.brown[800],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: recipes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                ingredientHave.isEmpty
                    ? Container(height: 0)
                    : Container(
                        height: 58,
                        color: const Color(0xFFF9CE8A),
                        child: ListView.builder(
                          itemCount: ingredientHave.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Container(
                              margin:
                                  const EdgeInsets.only(bottom: 8, left: 10),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    ingredientHave.removeAt(index);
                                    filterRecipesIngredient(ingredientHave);
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  overlayColor: Colors.transparent,
                                ),
                                child: Text(
                                  ingredientHave[index],
                                  style: const TextStyle(color: Colors.black),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ingredientHave = [];
                      ingredientController.clear();
                      searchController.clear();
                      filterRecipesName('');
                      await fetchRecipes();
                    },
                    color: Colors.white,
                    backgroundColor: const Color.fromARGB(255, 255, 171, 45),
                    child: ListView.builder(
                      itemCount: filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = filteredRecipes[index];
                        List<String> modifiedIngredients =
                            recipe['ingredients'].toString().split('/*/');

                        List<String> ingredients = [];

                        for (var ingredient in modifiedIngredients) {
                          List<String> parts = ingredient.split('/-/');

                          ingredients.add(parts[0]);
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    recipe['imglink'],
                                    width: 150,
                                    height: 120,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        recipe['name'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'วัตถุดิบ : ${ingredients.join(', ')}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          FutureBuilder<String>(
                                            future: fetchScore(recipe['id']),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const Text(
                                                    'คะแนน : ...');
                                              } else if (snapshot.hasError) {
                                                return const Text(
                                                    'คะแนน : err');
                                              } else {
                                                return Text(
                                                  'คะแนน : ${snapshot.data}',
                                                  style: const TextStyle(
                                                      fontSize: 14),
                                                );
                                              }
                                            },
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      RecipeDetailPage(
                                                          recipeId:
                                                              recipe['id']),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                            ),
                                            child: const Text(
                                              'เข้าชม',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
