import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://cgyiipfmplrrshevhpof.supabase.co',   // REMPLACEZ
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNneWlpcGZtcGxycnNoZXZocG9mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMzQ2MDgsImV4cCI6MjA5MDgxMDYwOH0.pFia6_FvyF9cth1T9JgjDXLhvJkjxoxLf5okIQlHTvI',                 // REMPLACEZ              // REMPLACEZ
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthService()),
        ),
      ],
      child: MaterialApp(
        title: 'BetPronos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme, // ✅ Nouveau thème appliqué
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
