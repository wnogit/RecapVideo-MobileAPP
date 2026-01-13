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
  // Auth initialization status - ပြီးမှ app စတင်မယ်
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Frame ပြီးမှ auth initialize စမယ် (build cycle conflict မဖြစ်အောင်)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    try {
      await ref.read(authProvider.notifier).initialize();
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    }
    // setState ခေါ်ခြင်း - addPostFrameCallback သုံးပြီး safe ဖြစ်အောင်
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
        }
      });
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

  // Splash Screen - Auth loading ပြနေစဉ် (Lottie Animation)
  Widget _buildSplashScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Always dark for splash
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation or Fallback Logo
            SizedBox(
              width: 180,
              height: 180,
              child: _buildLogoAnimation(),
            ),
            const SizedBox(height: 24),
            // App Name with gradient effect
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ).createShader(bounds),
              child: const Text(
                'RecapVideo.AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            Text(
              'AI Video Creation',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withAlpha(150),
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator with pulse animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              onEnd: () {}, // Animation will loop in widget tree rebuild
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withAlpha(30),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Logo Animation Widget - Actual Logo or Fallback
  Widget _buildLogoAnimation() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withAlpha(100),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/logo.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.video_library_rounded,
            size: 80,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
