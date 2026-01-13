import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/credits_service.dart';
import 'order_history_screen.dart';

/// Credits state
class CreditsState {
  final List<CreditPackage> packages;
  final CreditPackage? selectedPackage;
  final String? selectedPayment;
  final File? screenshotFile;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final Order? lastOrder;

  const CreditsState({
    this.packages = const [],
    this.selectedPackage,
    this.selectedPayment,
    this.screenshotFile,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.lastOrder,
  });

  CreditsState copyWith({
    List<CreditPackage>? packages,
    CreditPackage? selectedPackage,
    String? selectedPayment,
    File? screenshotFile,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    Order? lastOrder,
  }) => CreditsState(
    packages: packages ?? this.packages,
    selectedPackage: selectedPackage ?? this.selectedPackage,
    selectedPayment: selectedPayment ?? this.selectedPayment,
    screenshotFile: screenshotFile ?? this.screenshotFile,
    isLoading: isLoading ?? this.isLoading,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: error,
    lastOrder: lastOrder ?? this.lastOrder,
  );
}

/// Credits Notifier
class CreditsNotifier extends StateNotifier<CreditsState> {
  final CreditsService _service;
  final ImagePicker _picker = ImagePicker();

  CreditsNotifier(this._service) : super(const CreditsState()) {
    loadPackages();
  }

  Future<void> loadPackages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final packages = await _service.getPackages();
      state = state.copyWith(packages: packages, isLoading: false);
    } catch (e) {
      // Use mock data on error
      state = state.copyWith(
        packages: [
          CreditPackage(id: '1', name: 'Starter', credits: 5, priceMMK: 5000),
          CreditPackage(id: '2', name: 'Basic', credits: 10, priceMMK: 9000, isPopular: true),
          CreditPackage(id: '3', name: 'Pro', credits: 25, priceMMK: 20000),
          CreditPackage(id: '4', name: 'Business', credits: 50, priceMMK: 35000),
        ],
        isLoading: false,
      );
    }
  }

  void selectPackage(CreditPackage pkg) {
    state = state.copyWith(selectedPackage: pkg);
  }

  void selectPayment(String method) {
    state = state.copyWith(selectedPayment: method);
  }

  Future<void> pickScreenshot({bool fromCamera = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        state = state.copyWith(screenshotFile: File(image.path));
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pick image: $e');
    }
  }

  Future<bool> submitOrder() async {
    if (state.selectedPackage == null || state.selectedPayment == null) {
      state = state.copyWith(error: 'Please select package and payment method');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);
    try {
      // Create order
      final order = await _service.createOrder(
        packageId: state.selectedPackage!.id,
        paymentMethod: state.selectedPayment!,
      );

      // Upload screenshot if available
      if (state.screenshotFile != null) {
        await _service.uploadScreenshot(order.id, state.screenshotFile!);
      }

      state = state.copyWith(
        isSubmitting: false,
        lastOrder: order,
        selectedPackage: null,
        selectedPayment: null,
        screenshotFile: null,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = state.copyWith(
      selectedPackage: null,
      selectedPayment: null,
      screenshotFile: null,
      error: null,
    );
  }
}

/// Provider
final creditsNotifierProvider = StateNotifierProvider<CreditsNotifier, CreditsState>((ref) {
  return CreditsNotifier(ref.watch(creditsServiceProvider));
});

/// Payment methods
const _paymentMethods = [
  {'id': 'kpay', 'name': 'KBZ Pay', 'icon': '💳', 'account': '09-XXX-XXX-XXX'},
  {'id': 'wave', 'name': 'Wave Money', 'icon': '📱', 'account': '09-XXX-XXX-XXX'},
  {'id': 'cbpay', 'name': 'CB Pay', 'icon': '🏦', 'account': '09-XXX-XXX-XXX'},
];

/// Credits Screen - Connected to API
class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(creditsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('💎', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text('Buy Credits', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2a2a3a),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.history, size: 14, color: Colors.white70),
                          SizedBox(width: 4),
                          Text('History', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Packages
                          const Text('Select Package', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          ...state.packages.map((pkg) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PackageCard(
                              package: pkg,
                              isSelected: state.selectedPackage?.id == pkg.id,
                              onTap: () => ref.read(creditsNotifierProvider.notifier).selectPackage(pkg),
                            ),
                          )),

                          const SizedBox(height: 24),

                          // Payment Methods
                          const Text('Payment Method', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          ..._paymentMethods.map((m) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PaymentCard(
                              method: m,
                              isSelected: state.selectedPayment == m['id'],
                              onTap: () => ref.read(creditsNotifierProvider.notifier).selectPayment(m['id']!),
                            ),
                          )),

                          const SizedBox(height: 24),

                          // Screenshot upload
                          if (state.selectedPackage != null && state.selectedPayment != null) ...[
                            const Text('Payment Screenshot', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            _buildScreenshotPicker(context, ref, state),
                          ],

                          // Error
                          if (state.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(state.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                            ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
            ),

            // Submit button
            if (state.selectedPackage != null && state.selectedPayment != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: const Color(0xFF3a3a4a).withAlpha(100))),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${state.selectedPackage!.credits} Credits', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text('${_formatPrice(state.selectedPackage!.priceMMK)} MMK', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state.isSubmitting ? null : () async {
                            final success = await ref.read(creditsNotifierProvider.notifier).submitOrder();
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Order submitted! We\'ll review it soon.')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: state.isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Submit Order'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenshotPicker(BuildContext context, WidgetRef ref, CreditsState state) {
    final notifier = ref.read(creditsNotifierProvider.notifier);

    if (state.screenshotFile != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withAlpha(100)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.file(state.screenshotFile!, height: 150, width: double.infinity, fit: BoxFit.cover),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => notifier.reset(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => notifier.pickScreenshot(fromCamera: false),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3a3a4a)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.photo_library, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  const Text('Gallery', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => notifier.pickScreenshot(fromCamera: true),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3a3a4a)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.camera_alt, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  const Text('Camera', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

/// Package Card
class _PackageCard extends StatelessWidget {
  final CreditPackage package;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackageCard({required this.package, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(20) : const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFF3a3a4a), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: isSelected ? [const Color(0xFF8B5CF6), const Color(0xFFEC4899)] : [const Color(0xFF3a3a4a), const Color(0xFF2a2a3a)]),
              ),
              child: Center(child: Text('${package.credits}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(package.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      if (package.isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.withAlpha(40), borderRadius: BorderRadius.circular(10)),
                          child: const Text('🔥 Popular', style: TextStyle(fontSize: 10, color: Colors.orange)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${package.credits} credits', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Text('${_formatPrice(package.priceMMK)} ks', style: TextStyle(color: isSelected ? AppColors.primary : Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) => price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

/// Payment Card
class _PaymentCard extends StatelessWidget {
  final Map<String, String> method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentCard({required this.method, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withAlpha(20) : const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFF3a3a4a), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Text(method['icon']!, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  Text(method['account']!, style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}
