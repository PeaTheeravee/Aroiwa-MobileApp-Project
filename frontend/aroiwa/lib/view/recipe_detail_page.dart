import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RecipeDetailPage extends StatefulWidget {
  final int recipeId;

  const RecipeDetailPage({super.key, required this.recipeId});

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  String recipeName = '';
  String recipeImg = '';
  String recipeIngredient = '';
  String recipeMethod = '';
  int recipeUserId = 0;
  int currentUserId = 0;

  double recipeScore = 0.0;
  int recipeScoreCount = 0;
  int giveScore = 0;
  String goLogin = 'โปรดเข้าสู่ระบบก่อนให้คะแนน';

  bool postCheck = false;

  String userName = '';
  String userUsername = '';
  List<String> ingredientsList = [];
  List<String> ingredientsCountList = [];
  List<String> methodsList = [];

  Icon starFirst = const Icon(
    Icons.star_border_rounded,
    size: 50,
    color: Colors.black,
  );
  Icon starSecond = const Icon(
    Icons.star_border_rounded,
    size: 50,
    color: Colors.black,
  );
  Icon starThird = const Icon(
    Icons.star_border_rounded,
    size: 50,
    color: Colors.black,
  );
  Icon starFourt = const Icon(
    Icons.star_border_rounded,
    size: 50,
    color: Colors.black,
  );
  Icon starFift = const Icon(
    Icons.star_border_rounded,
    size: 50,
    color: Colors.black,
  );

  @override
  void initState() {
    super.initState();
    fetchRecipes();
    fetchScore();
    fetchPersonalScore();
  }

  Future<void> fetchRecipes() async {
    int recipeId = widget.recipeId;

    final url = Uri.parse('http://54.169.248.246:8000/recipes/$recipeId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        recipeName = json.decode(utf8.decode(response.bodyBytes))['name'];
        recipeImg = json.decode(utf8.decode(response.bodyBytes))['imglink'];
        recipeIngredient =
            json.decode(utf8.decode(response.bodyBytes))['ingredients'];
        recipeMethod = json.decode(utf8.decode(response.bodyBytes))['method'];
        recipeUserId = json.decode(utf8.decode(response.bodyBytes))['user_id'];
        ingredientsList = recipeIngredient.split('/*/');
        methodsList = recipeMethod.split('/*/');
      });

      await fetchRecipeUser();
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  Future<void> fetchRecipeUser() async {
    final url = Uri.parse('http://54.169.248.246:8000/users/$recipeUserId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        userName = json.decode(utf8.decode(response.bodyBytes))['first_name'];
        userUsername = json.decode(utf8.decode(response.bodyBytes))['username'];
      });
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  Future<void> fetchScore() async {
    int recipeId = widget.recipeId;

    final url = Uri.parse('http://54.169.248.246:8000/scores/$recipeId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        recipeScore = json.decode(utf8.decode(response.bodyBytes))['avg_score'];
        recipeScoreCount =
            json.decode(utf8.decode(response.bodyBytes))['count'];
      });
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  Future<void> fetchPersonalScore() async {
    int recipeId = widget.recipeId;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      print('User not logged in');
      return;
    }

    final url = Uri.parse(
        'http://54.169.248.246:8000/scores/personal/$userId/$recipeId');

    try {
      final response = await http.get(
        url,
        headers: <String, String>{
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final score = jsonDecode(response.body);
        print('User score: ${score['score']}');
        setState(() {
          starFirst = Icon(
              score['score'] >= 1
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 50,
              color: score['score'] >= 1 ? Colors.amber : Colors.black);

          starSecond = Icon(
              score['score'] >= 2
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 50,
              color: score['score'] >= 2 ? Colors.amber : Colors.black);

          starThird = Icon(
              score['score'] >= 3
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 50,
              color: score['score'] >= 3 ? Colors.amber : Colors.black);

          starFourt = Icon(
              score['score'] >= 4
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 50,
              color: score['score'] >= 4 ? Colors.amber : Colors.black);

          starFift = Icon(
              score['score'] >= 5
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              size: 50,
              color: score['score'] >= 5 ? Colors.amber : Colors.black);
        });
      } else {
        print('Failed to retrieve score. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred while retrieving score: $e');
    }
  }

  Future<bool> postScoreCheck(int recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final accessToken = prefs.getString('access_token');

    if (userId == null || accessToken == null) {
      // ถ้า userId หรือ accessToken เป็น null ให้จัดการ error
      print('User not logged in');
      return false;
    }

    // สร้าง URL สำหรับการเรียก API
    final url = Uri.parse(
        'http://54.169.248.246:8000/scores/canpost/$userId/$recipeId');

    try {
      // เรียก API ด้วย access token
      final response = await http.get(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        // แปลงผลลัพธ์จาก JSON และคืนค่าความเป็นจริง
        final result = json.decode(utf8.decode(response.bodyBytes));
        return result as bool;
      } else {
        print(
            'Failed to check score permission. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error occurred while checking score permission: $e');
      return false;
    }
  }

  Future<void> postScore(int score, int recipeId) async {
    final url = Uri.parse('http://54.169.248.246:8000/scores/create');
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final accessToken = prefs.getString('access_token');

    final canPost = await postScoreCheck(recipeId);

    if (userId == null) {
      // ถ้า userId เป็น null ให้แสดงข้อความเตือนหรือจัดการ error
      print('User ID is null, cannot post score.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
              child: Text('โปรดเข้าสู่ระบบก่อนให้คะแนน',
                  style: TextStyle(color: Colors.brown[800], fontSize: 16))),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color.fromARGB(255, 255, 171, 45),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // ปรับมุมโค้ง
          ),
        ),
      );
      return;
    }

    final Map<String, int> data = {
      'score': score,
      'recipe_id': recipeId,
      'user_id': userId,
    };

    if (accessToken != null) {
      if (userId != recipeUserId) {
        if (canPost) {
          print(data);
          final response = await http.post(
            url,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $accessToken'
            },
            body: jsonEncode(data),
          );
          if (response.statusCode == 200) {
            print('statusCode : 200 (create score)');
            setState(() {
              fetchScore();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Center(
                    child: Text('ให้คะแนนสำเร็จ',
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
            debugPrint(
                'Failed to post data. Status code: ${response.statusCode}');
          }
        } else {
          final url = Uri.parse(
              'http://54.169.248.246:8000/scores/updatescore/$userId/$recipeId/$score');

          try {
            final response = await http.put(
              url,
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
                'Authorization': 'Bearer $accessToken',
              },
            );

            if (response.statusCode == 200) {
              print('Score updated successfully');
              setState(() {
                fetchScore();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Center(
                      child: Text('เปลี่ยนคะแนนสำเร็จ',
                          style: TextStyle(
                              color: Colors.brown[800], fontSize: 16))),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color.fromARGB(255, 255, 171, 45),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0), // ปรับมุมโค้ง
                  ),
                ),
              );
            } else {
              print(
                  'Failed to update score. Status code: ${response.statusCode}');
            }
          } catch (e) {
            print('Error occurred while updating score: $e');
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Center(
                child: Text('ไม่สามาถให้คะแนนสูตรของตัวเองได้',
                    style: TextStyle(color: Colors.brown[800], fontSize: 16))),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color.fromARGB(255, 255, 171, 45),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0), // ปรับมุมโค้ง
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Center(
              child: Text(goLogin,
                  style: TextStyle(color: Colors.brown[800], fontSize: 16))),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color.fromARGB(255, 255, 171, 45),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // ปรับมุมโค้ง
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: const Color(0xFFF9C784),
          title: Text(
            recipeName,
            style: const TextStyle(fontFamily: 'Pacifico', fontSize: 26),
          )),
      body: SingleChildScrollView(
        // padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            Image.network(
              recipeImg,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child,
                  ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1)
                        : null,
                  ),
                );
              },
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                return const Center(child: CircularProgressIndicator());
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('โดย: $userName ',
                              style: const TextStyle(fontSize: 18)),
                          Text('@$userUsername',
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.black54))
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 30),
                          Text(
                            recipeScore.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 24),
                          ),
                          const Text('  ทั้งหมด '),
                          Text(recipeScoreCount.toString())
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Ingredients
                  const Text('ส่วนผสม',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...ingredientsList.map((ingredient) => Text(
                      '- ${ingredient.replaceAll('/-/', ' ')}',
                      style: const TextStyle(fontSize: 18))),

                  const SizedBox(height: 20),

                  // Method
                  const Text('วิธีทำ',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...methodsList.map((method) =>
                      Text('- $method', style: const TextStyle(fontSize: 18))),
                  const SizedBox(height: 20),
                  // Star Rating Section
                  // const Text('ให้คะแนน:', style: TextStyle(fontSize: 20)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            starFirst = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);

                            starSecond = const Icon(Icons.star_border_rounded,
                                size: 50, color: Colors.black);
                            starThird = const Icon(Icons.star_border_rounded,
                                size: 50, color: Colors.black);
                            starFourt = const Icon(Icons.star_border_rounded,
                                size: 50, color: Colors.black);
                            starFift = const Icon(Icons.star_border_rounded,
                                size: 50, color: Colors.black);
                            giveScore = 1;
                          });
                        },
                        icon: starFirst,
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            starFirst = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);
                            starSecond = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);

                            starThird = const Icon(Icons.star_border_rounded,
                                size: 50, color: Colors.black);
                            starFourt = const Icon(Icons.star_border_rounded,
                                size: 50, color: Colors.black);
                            starFift = const Icon(Icons.star_border_rounded,
                                size: 50, color: Colors.black);
                            giveScore = 2;
                          });
                        },
                        icon: starSecond,
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            starFirst = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);
                            starSecond = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);
                            starThird = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);

                            starFourt = const Icon(Icons.star_border_rounded,
                                size: 50, color: Colors.black);
                            starFift = const Icon(Icons.star_border_rounded,
                                size: 50, color: Colors.black);
                            giveScore = 3;
                          });
                        },
                        icon: starThird,
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            starFirst = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);
                            starSecond = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);
                            starThird = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);
                            starFourt = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);

                            starFift = const Icon(Icons.star_border_rounded,
                                size: 50, color: Colors.black);
                            giveScore = 4;
                          });
                        },
                        icon: starFourt,
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            starFirst = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);
                            starSecond = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);
                            starThird = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);
                            starFourt = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);
                            starFift = const Icon(Icons.star_rounded,
                                size: 50, color: Colors.amber);
                            giveScore = 5;
                          });
                        },
                        icon: starFift,
                      ),
                    ],
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        postScore(giveScore, widget.recipeId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text(
                        'ให้คะแนน',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Recipe name and user
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 255, 225, 185),
    );
  }
}
