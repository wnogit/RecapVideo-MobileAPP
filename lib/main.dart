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
  @override
  void initState() {
    super.initState();
    // Initialize auth (check for stored token)
    Future.microtask(() => ref.read(authProvider.notifier).initialize());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    // Watch theme state to rebuild when it changes
    final currentTheme = ref.watch(themeProvider);
    
    // Convert AppThemeMode to ThemeMode
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
    );
  }
}
