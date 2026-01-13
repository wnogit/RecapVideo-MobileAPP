import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/api/credits_service.dart';
import 'order_history_screen.dart';

/// Credit packages data
const _creditPackages = [
  {'credits': 20, 'price': 15000},
  {'credits': 50, 'price': 35000},
  {'credits': 100, 'price': 65000},
  {'credits': 200, 'price': 120000},
];

/// Payment methods with colors
const _paymentMethods = [
  {'id': 'kbz', 'name': 'KBZ Pay', 'color': 0xFFE5E7EB, 'textColor': 0xFF374151},
  {'id': 'wave', 'name': 'Wave Pay', 'color': 0xFFD1FAE5, 'textColor': 0xFF059669},
  {'id': 'cb', 'name': 'CB Pay', 'color': 0xFFFCE7F3, 'textColor': 0xFF9333EA},
  {'id': 'aya', 'name': 'AYA Pay', 'color': 0xFFFEF3C7, 'textColor': 0xFFD97706},
];

/// Account info
const _accountInfo = {
  'name': 'RecapVideo.AI',
  'phone': '09777777777',
};

/// Order flow state
class OrderFlowState {
  final int currentStep; // 0, 1, 2
  final int? selectedPackageIndex;
  final String? selectedPaymentId;
  final String transactionId;
  final File? screenshot;
  final bool isSubmitting;
  final String? error;

  const OrderFlowState({
    this.currentStep = 0,
    this.selectedPackageIndex,
    this.selectedPaymentId,
    this.transactionId = '',
    this.screenshot,
    this.isSubmitting = false,
    this.error,
  });

  OrderFlowState copyWith({
    int? currentStep,
    int? selectedPackageIndex,
    String? selectedPaymentId,
    String? transactionId,
    File? screenshot,
    bool? isSubmitting,
    String? error,
  }) => OrderFlowState(
    currentStep: currentStep ?? this.currentStep,
    selectedPackageIndex: selectedPackageIndex ?? this.selectedPackageIndex,
    selectedPaymentId: selectedPaymentId ?? this.selectedPaymentId,
    transactionId: transactionId ?? this.transactionId,
    screenshot: screenshot ?? this.screenshot,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    error: error,
  );

  bool get canProceedStep1 => selectedPackageIndex != null;
  bool get canProceedStep2 => selectedPaymentId != null;
  bool get canSubmit => transactionId.length == 7 && screenshot != null;

  Map<String, dynamic>? get selectedPackage => 
    selectedPackageIndex != null ? _creditPackages[selectedPackageIndex!] : null;
}

/// Order flow notifier
class OrderFlowNotifier extends StateNotifier<OrderFlowState> {
  final ImagePicker _picker = ImagePicker();
  final CreditsService _service;

  OrderFlowNotifier(this._service) : super(const OrderFlowState());

  void selectPackage(int index) {
    state = state.copyWith(selectedPackageIndex: index);
  }

  void selectPayment(String id) {
    state = state.copyWith(selectedPaymentId: id);
  }

  void setTransactionId(String value) {
    // Only allow 7 digits
    if (value.length <= 7) {
      state = state.copyWith(transactionId: value);
    }
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  Future<void> pickScreenshot({bool fromCamera = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        state = state.copyWith(screenshot: File(image.path));
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to pick image');
    }
  }

  void clearScreenshot() {
    state = OrderFlowState(
      currentStep: state.currentStep,
      selectedPackageIndex: state.selectedPackageIndex,
      selectedPaymentId: state.selectedPaymentId,
      transactionId: state.transactionId,
      screenshot: null,
    );
  }

  Future<bool> submitOrder() async {
    if (!state.canSubmit) return false;

    state = state.copyWith(isSubmitting: true, error: null);
    try {
      // Create order via API
      final pkg = _creditPackages[state.selectedPackageIndex!];
      final order = await _service.createOrder(
        packageId: pkg['credits'].toString(),
        paymentMethod: state.selectedPaymentId!,
      );

      // Upload screenshot
      if (state.screenshot != null) {
        await _service.uploadScreenshot(order.id, state.screenshot!);
      }

      // Reset state
      state = const OrderFlowState();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  void reset() {
    state = const OrderFlowState();
  }
}

/// Provider
final orderFlowProvider = StateNotifierProvider<OrderFlowNotifier, OrderFlowState>((ref) {
  return OrderFlowNotifier(ref.watch(creditsServiceProvider));
});

/// Main Credits Screen
class CreditsScreen extends ConsumerWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderFlowProvider);
    final notifier = ref.read(orderFlowProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Row(
          children: [
            const Text('Buy Credits', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Text('💎', style: TextStyle(fontSize: 20)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Step 1: Select Package
                    _buildStepHeader(
                      stepNumber: 1,
                      title: 'Select Package',
                      isActive: state.currentStep == 0,
                      isDone: state.currentStep > 0,
                    ),
                    if (state.currentStep == 0) ...[
                      const SizedBox(height: 12),
                      _buildPackageSelection(state, notifier),
                      const SizedBox(height: 16),
                      _buildStepButtons(
                        context: context,
                        showBack: false,
                        onContinue: state.canProceedStep1 ? notifier.nextStep : null,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Step 2: Payment Method
                    _buildStepHeader(
                      stepNumber: 2,
                      title: 'Payment Method',
                      isActive: state.currentStep == 1,
                      isDone: state.currentStep > 1,
                    ),
                    if (state.currentStep == 1) ...[
                      const SizedBox(height: 12),
                      _buildSummaryCard(state),
                      const SizedBox(height: 16),
                      _buildPaymentSelection(context, state, notifier),
                      const SizedBox(height: 16),
                      _buildStepButtons(
                        context: context,
                        showBack: true,
                        onBack: notifier.prevStep,
                        onContinue: state.canProceedStep2 ? notifier.nextStep : null,
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Step 3: Confirmation
                    _buildStepHeader(
                      stepNumber: 3,
                      title: 'Confirmation',
                      isActive: state.currentStep == 2,
                      isDone: false,
                    ),
                    if (state.currentStep == 2) ...[
                      const SizedBox(height: 12),
                      _buildConfirmationStep(context, state, notifier, ref),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader({
    required int stepNumber,
    required String title,
    required bool isActive,
    required bool isDone,
    bool showLine = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.success
                    : isActive
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '$stepNumber',
                        style: TextStyle(
                          color: isActive ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: isActive || isDone ? Colors.white : AppColors.textSecondary,
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        // Vertical connecting line
        if (showLine && !isActive)
          Container(
            margin: const EdgeInsets.only(left: 13),
            width: 2,
            height: 20,
            color: isDone ? AppColors.success : AppColors.surfaceVariant,
          ),
      ],
    );
  }

  Widget _buildPackageSelection(OrderFlowState state, OrderFlowNotifier notifier) {
    return Column(
      children: List.generate(_creditPackages.length, (index) {
        final pkg = _creditPackages[index];
        final isSelected = state.selectedPackageIndex == index;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 40),
          child: GestureDetector(
            onTap: () => notifier.selectPackage(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Text('💎', style: TextStyle(fontSize: isSelected ? 22 : 18)),
                  const SizedBox(width: 12),
                  Text(
                    '${pkg['credits']} Credits',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${_formatPrice(pkg['price'] as int)} MMK',
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(OrderFlowState state) {
    final pkg = state.selectedPackage;
    if (pkg == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(left: 40),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Text('📦', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            '${pkg['credits']} Credits',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          const Text(' - ', style: TextStyle(color: AppColors.textSecondary)),
          Text(
            '${_formatPrice(pkg['price'] as int)} MMK',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSelection(BuildContext context, OrderFlowState state, OrderFlowNotifier notifier) {
    return Container(
      margin: const EdgeInsets.only(left: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Account info
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(_accountInfo['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(_accountInfo['phone']!, style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _copyToClipboard(context, _accountInfo['phone']!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy, size: 14, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text('Copy', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Payment buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _paymentMethods.map((method) {
              final isSelected = state.selectedPaymentId == method['id'];
              return GestureDetector(
                onTap: () => notifier.selectPayment(method['id'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(method['color'] as int),
                    borderRadius: BorderRadius.circular(24),
                    border: isSelected ? Border.all(color: AppColors.primary, width: 2) : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        method['name'] as String,
                        style: TextStyle(
                          color: Color(method['textColor'] as int),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.check, size: 16, color: Color(method['textColor'] as int)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep(BuildContext context, OrderFlowState state, OrderFlowNotifier notifier, WidgetRef ref) {
    final pkg = state.selectedPackage;
    final payment = _paymentMethods.firstWhere((m) => m['id'] == state.selectedPaymentId, orElse: () => {});

    return Container(
      margin: const EdgeInsets.only(left: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📋 ORDER SUMMARY', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 12),
                _buildSummaryRow('Package', '${pkg?['credits']} Credits'),
                _buildSummaryRow('Price', '${_formatPrice(pkg?['price'] as int? ?? 0)} MMK'),
                _buildSummaryRow('Payment', payment['name'] as String? ?? ''),
                const Divider(color: AppColors.surfaceVariant, height: 24),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.phone, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_accountInfo['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          Text(_accountInfo['phone']!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _copyToClipboard(context, _accountInfo['phone']!),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Transaction ID
          const Text('Transaction ID (last 7 digits)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    maxLength: 7,
                    style: const TextStyle(color: Colors.white, letterSpacing: 6, fontSize: 16),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: '- - - - - - -',
                      hintStyle: TextStyle(color: AppColors.textTertiary.withOpacity(0.5), letterSpacing: 6),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: notifier.setTransactionId,
                  ),
                ),
                Text('${state.transactionId.length}/7', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Screenshot upload
          if (state.screenshot != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(state.screenshot!, height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: notifier.clearScreenshot,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: () => notifier.pickScreenshot(),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceVariant),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Upload Screenshot', style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),

          // Error message
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(state.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],

          const SizedBox(height: 16),
          _buildStepButtons(
            context: context,
            showBack: true,
            onBack: notifier.prevStep,
            isSubmit: true,
            isLoading: state.isSubmitting,
            onContinue: state.canSubmit
                ? () async {
                    final success = await ref.read(orderFlowProvider.notifier).submitOrder();
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Order submitted! We\'ll review it soon.')),
                      );
                      Navigator.pop(context);
                    }
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStepButtons({
    required BuildContext context,
    required bool showBack,
    VoidCallback? onBack,
    VoidCallback? onContinue,
    bool isSubmit = false,
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        children: [
          if (showBack) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.surfaceVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: onContinue != null ? AppColors.primaryGradient : null,
                color: onContinue == null ? AppColors.surfaceVariant : null,
                borderRadius: BorderRadius.circular(24),
              ),
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isSubmit ? 'Submit' : 'Continue', style: const TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('မှာဝယ်ရန် အဆင့် ၃ ဆင့်', style: TextStyle(color: Colors.white)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('၁။ မှာဝယ်မည့် ပက်ကေ့ နှင့် ငွေပမာဏ ရွေးချယ်ပါ', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            Text('၂။ ငွေလွှဲမည့် အကောင့်ကို ရွေးချယ်ပြီး ရွေးချယ်ထားသော အကောင့်ကိုသာ ငွေလွှဲရပါမည်', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 12),
            Text('၃။ ငွေလွှဲပြီးမှ Transaction ID နောက်ဆုံး ၇ လုံး နှင့် Screenshot ကို ပူးတွဲတင်ပါ', style: TextStyle(color: Colors.white70)),
            SizedBox(height: 16),
            Text('ကြာချိန် ၃ မိနစ်မှ ၃၀ အထိ ကြာနိုင်ပါသည်', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $text'), duration: const Duration(seconds: 1)),
    );
  }

  String _formatPrice(int price) => price.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}
