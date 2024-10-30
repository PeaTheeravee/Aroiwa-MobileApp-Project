import 'package:aroiwa/view/recipe_owner_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileDetailPage extends StatefulWidget {
  final Function(int) setPage;

  const ProfileDetailPage({super.key, required this.setPage});

  @override
  _ProfileDetailPageState createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  Map<String, dynamic>? _userData;
  String _errorMessage = '';
  bool _isLoading = true;

  List recipes = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> fetchRecipes() async {
    final url = Uri.parse('http://54.169.248.246:8000/recipes/all');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        List allRecipes =
            json.decode(utf8.decode(response.bodyBytes))['recipes'];

        recipes = allRecipes
            .where((recipe) => recipe['user_id'] == _userData?['id'])
            .toList();
      });
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      setState(() {
        _errorMessage = 'Unauthorized. Please log in again.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://54.169.248.246:8000/users/me'), // Updated URL
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _userData = data;
          _isLoading = false;
        });
        print('User Data: ${_userData?['id']}');
        await prefs.setInt('user_id', data['id']);

        fetchRecipes();
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Unauthorized. Please log in again.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load user profile. Please try again later.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to connect to the internet. Please try later.';
        _isLoading = false;
      });
    }
  }

  Future<String> fetchScore(int recipeId) async {
    final url = Uri.parse('http://54.169.248.246:8000/scores/$recipeId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      print(
          json.decode(utf8.decode(response.bodyBytes))['avg_score'].toString());
      return json
          .decode(utf8.decode(response.bodyBytes))['avg_score']
          .toString();
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: Container(
          color: const Color(0xFFF9CE8A),
          child: AppBar(
            title: _userData != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Text(
                            '${_userData!['first_name']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '@${_userData!['username']}',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('access_token'); // ลบ access token
                          await prefs.remove('user_id');
                          await prefs.setString('statelogin', 'off');

                          widget.setPage(4); // เปลี่ยนไปที่หน้า Login
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[800],
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                        'Loading...',
                        style: TextStyle(fontSize: 18),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('access_token'); // ลบ access token
                          await prefs.remove('user_id');
                          await prefs.setString('statelogin', 'off');

                          widget.setPage(4); // เปลี่ยนไปที่หน้า Login
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[800],
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF9CE8A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userData != null
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'สูตรของฉัน',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      recipes.isNotEmpty
                          ? Expanded(
                              child: RefreshIndicator(
                                onRefresh: fetchRecipes,
                                color: Colors.white,
                                backgroundColor:
                                    const Color.fromARGB(255, 255, 171, 45),
                                child: ListView.builder(
                                  itemCount: recipes.length,
                                  itemBuilder: (context, index) {
                                    final recipe = recipes[index];
                                    List<String> modifiedIngredients =
                                        recipe['ingredients']
                                            .toString()
                                            .split('/*/');

                                    List<String> ingredients = [];

                                    for (var ingredient
                                        in modifiedIngredients) {
                                      // แยกค่าโดยใช้ '/-/'
                                      List<String> parts =
                                          ingredient.split('/-/');

                                      // ตรวจสอบว่ามีค่า 2 ค่าใน parts หรือไม่
                                      ingredients.add(parts[0]);
                                    }

                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 10),
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.all(
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
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    recipe['name'],
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'วัตถุดิบ : ${ingredients.join(', ')}',
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      FutureBuilder<String>(
                                                        future: fetchScore(
                                                            recipe['id']),
                                                        builder: (context,
                                                            snapshot) {
                                                          if (snapshot
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .waiting) {
                                                            return const Text(
                                                                'คะแนน : ...');
                                                          } else if (snapshot
                                                              .hasError) {
                                                            return const Text(
                                                                'คะแนน : err');
                                                          } else {
                                                            return Text(
                                                              'คะแนน : ${snapshot.data}',
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          14),
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
                                                                  RecipeOwnerDetailPage(
                                                                      recipeId:
                                                                          recipe[
                                                                              'id']),
                                                            ),
                                                          );
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              Colors.orange,
                                                        ),
                                                        child: const Text(
                                                          'เข้าชม',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white),
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
                            )
                          : Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'ยังไม่มีสูตรของฉัน',
                                      style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                        'คุณสามารถแชร์สูตรใน Aroiwa ได้โดยกดปุ่มด้านล่างนี้',
                                        style: TextStyle(fontSize: 15)),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                        onPressed: () {
                                          widget.setPage(1);
                                        },
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange),
                                        child: const Text('เพิ่มสูตร',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white)))
                                  ],
                                ),
                              ),
                            )
                    ],
                  ),
                )
              : Center(child: Text(_errorMessage)),
    );
  }
}
