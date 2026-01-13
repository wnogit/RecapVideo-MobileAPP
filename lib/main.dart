import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: RecapVideoApp(),
    ),
  );
}

class RecapVideoApp extends ConsumerStatefulWidget {
  const RecapVideoApp({super.key});

  @override
  ConsumerState<RecapVideoApp> createState() => _RecapVideoAppState();
}

class _RecapVideoAppState extends ConsumerState<RecapVideoApp> {
  // Auth initialization future - ပြီးမှ app စတင်မယ်
  late Future<void> _authInitFuture;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Auth provider initialize - token စစ်ပြီး user data ယူမယ်
    _authInitFuture = _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    await ref.read(authProvider.notifier).initialize();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    // Theme state ကို watch လုပ်မယ်
    final currentTheme = ref.watch(themeProvider);
    
    // AppThemeMode ကနေ ThemeMode ပြောင်းမယ်
    ThemeMode themeMode;
    switch (currentTheme) {
      case AppThemeMode.light:
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        themeMode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        themeMode = ThemeMode.system;
        break;
    }
    
    return MaterialApp.router(
      title: 'RecapVideo.ai',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      // Auth initialize မပြီးခင် splash screen ပြမယ်
      builder: (context, child) {
        if (!_isInitialized) {
          return _buildSplashScreen(context);
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }

  // Splash Screen - Auth loading ပြနေစဉ်
  Widget _buildSplashScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? const Color(0xFF0A0A0A) 
          : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
              errorBuilder: (_, __, ___) => Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.video_library, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            const Text(
              'RecapVideo.AI',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 32),
            // Loading indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
