import 'package:aroiwa/view/add_recipe_page.dart';
import 'package:aroiwa/view/profile_detail_page.dart';
import 'package:aroiwa/view/recipe_detail_page.dart';
import 'package:aroiwa/view/recipes_list_page.dart';
import 'package:aroiwa/view/login_page.dart';
import 'package:aroiwa/view/register_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _navIndex = 0;
  int _pageIndex = 0;
  int _recipeId = 3;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      RecipesListPage(setPage: _setPage, setRecipeId: _setRecipeId),
      AddRecipePage(setPage: _setPage),
      ProfileDetailPage(setPage: _setPage), // Updated constructor
      RecipeDetailPage(recipeId: _recipeId),
      LoginPage(setPage: _setPage),
    ];
  }

  void _setPage(int index) {
    setState(() {
      _pageIndex = index;
      _navIndex = index == 3 ? 0 : index;
      if (index == 4) {
        _navIndex = 2;
      }
    });
  }

  void _setRecipeId(int recipeId) {
    setState(() {
      _recipeId = recipeId;
      debugPrint(_recipeId.toString());
    });
  }

  void _checkLoginStatus(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final statelogin = prefs.getString('statelogin') ?? 'off';

    if (statelogin == 'on') {
      _setPage(index);
    } else if (index == 0) {
      _setPage(index);
    } else {
      _setPage(4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aroiwa',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFFF9CE8A),
        body: _pages[_pageIndex],
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color.fromARGB(255, 255, 171, 45),
            selectedItemColor: Colors.brown[800],
            unselectedItemColor: Colors.brown,
            currentIndex: _navIndex,
            onTap: (index) {
              _checkLoginStatus(index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_box_outlined),
                label: 'Add',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      routes: {
        '/recipes_list': (context) =>
            RecipesListPage(setPage: _setPage, setRecipeId: _setRecipeId),
        '/register': (context) => RegisterPage(),
        '/login': (context) => LoginPage(setPage: _setPage),
        '/recipe_detail': (context) => RecipeDetailPage(recipeId: _recipeId),
      },
    );
  }
}
