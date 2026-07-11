import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService()), // AuthService importé
        ),
      ],
      child: MaterialApp(
        title: 'BetPronos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A0A0A),
          // ... autres thèmes
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(), // si SplashScreen est const
          '/login': (context) => const LoginScreen(), // pas de const (enlève const)
          '/home': (context) => const HomeScreen(), // idem
        },
      ),
    );
  }
}
