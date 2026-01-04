import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'home.dart';
import 'login.dart';
import 'register.dart';
import 'admin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter _router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => Home()),
        GoRoute(path: '/register', builder: (context, state) => Register()),
        GoRoute(path: '/login', builder: (context, state) => Login()),
        GoRoute(path: '/admin', builder: (context, state) => Admin()),
      ],
    );

    return MaterialApp.router(title: "Mobile Zone",debugShowCheckedModeBanner: false,routerConfig: _router,);
  }
}
