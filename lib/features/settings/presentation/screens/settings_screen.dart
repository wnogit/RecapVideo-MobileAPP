import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/constants/app_colors.dart';

/// Settings Screen with Theme and Language options
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final currentLang = ref.watch(languageProvider);
    final strings = ref.watch(stringsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.settings),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          _buildSectionHeader(context, '🎨 ${strings.theme}'),
          const SizedBox(height: 12),
          _buildThemeSelector(context, ref, currentTheme, strings, isDark),
          
          const SizedBox(height: 24),
          
          // Language Section
          _buildSectionHeader(context, '🌐 ${strings.language_}'),
          const SizedBox(height: 12),
          _buildLanguageSelector(context, ref, currentLang),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionHeader(context, 'ℹ️ About'),
          const SizedBox(height: 12),
          _buildAboutCard(context, isDark),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref, AppThemeMode current, AppStrings strings, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF3a3a4a) : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildThemeOption(
            context, ref,
            AppThemeMode.light,
            '☀️ ${strings.light}',
            current == AppThemeMode.light,
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF3a3a4a) : Colors.grey.shade200),
          _buildThemeOption(
            context, ref,
            AppThemeMode.dark,
            '🌙 ${strings.dark}',
            current == AppThemeMode.dark,
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF3a3a4a) : Colors.grey.shade200),
          _buildThemeOption(
            context, ref,
            AppThemeMode.system,
            '📱 ${strings.system}',
            current == AppThemeMode.system,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, WidgetRef ref, AppThemeMode mode, String label, bool isSelected) {
    return ListTile(
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : const Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, WidgetRef ref, AppLanguage current) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF3a3a4a) : Colors.grey.shade200),
      ),
      child: Column(
        children: AppLanguage.values.map((lang) {
          final isSelected = current == lang;
          return Column(
            children: [
              ListTile(
                leading: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                title: Text(lang.label),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : const Icon(Icons.circle_outlined, color: Colors.grey),
                onTap: () => ref.read(languageProvider.notifier).setLanguage(lang),
              ),
              if (lang != AppLanguage.values.last)
                Divider(height: 1, color: isDark ? const Color(0xFF3a3a4a) : Colors.grey.shade200),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF3a3a4a) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/logo.png', width: 40, height: 40),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RecapVideo.AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Version 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'AI-powered video creation platform for content creators.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
