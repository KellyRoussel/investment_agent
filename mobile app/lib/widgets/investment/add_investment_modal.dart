import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/investment.dart';
import '../common/app_button.dart';
import '../common/app_input.dart';
import '../common/app_dropdown.dart';
import '../common/error_banner.dart';

class AddInvestmentModal extends StatefulWidget {
  final Future<void> Function(InvestmentCreate data) onAdd;

  const AddInvestmentModal({super.key, required this.onAdd});

  @override
  State<AddInvestmentModal> createState() => _AddInvestmentModalState();
}

class _AddInvestmentModalState extends State<AddInvestmentModal> {
  final _formKey = GlobalKey<FormState>();
  String _accountType = 'PEA';
  final _tickerController = TextEditingController();
  final _isinController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime? _purchaseDate;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _tickerController.dispose();
    _isinController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.cyan,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_purchaseDate == null) {
      setState(() => _error = 'Please select a purchase date');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = InvestmentCreate(
        accountType: _accountType,
        tickerSymbol: _accountType == 'PEA' ? _tickerController.text.trim().toUpperCase() : null,
        isin: _accountType == 'CTO' ? _isinController.text.trim().toUpperCase() : null,
        purchaseDate: DateFormat('yyyy-MM-dd').format(_purchaseDate!),
        quantity: double.parse(_quantityController.text.trim()),
      );
      await widget.onAdd(data);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Investment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_error != null) ...[
                ErrorBanner(
                  message: _error!,
                  onDismiss: () => setState(() => _error = null),
                ),
                const SizedBox(height: 16),
              ],

              // Account type
              AppDropdown(
                label: 'Account Type',
                value: _accountType,
                required: true,
                items: const [
                  DropdownMenuItem(value: 'PEA', child: Text('PEA')),
                  DropdownMenuItem(value: 'CTO', child: Text('CTO')),
                ],
                onChanged: (v) => setState(() => _accountType = v ?? 'PEA'),
              ),
              const SizedBox(height: 16),

              // Conditional field
              if (_accountType == 'PEA')
                AppInput(
                  label: 'Ticker Symbol',
                  controller: _tickerController,
                  required: true,
                  hintText: 'e.g., AAPL',
                  textInputAction: TextInputAction.next,
                  validator: validateTicker,
                )
              else
                AppInput(
                  label: 'ISIN',
                  controller: _isinController,
                  required: true,
                  hintText: 'e.g., US0378331005',
                  textInputAction: TextInputAction.next,
                  validator: validateIsin,
                ),
              const SizedBox(height: 16),

              // Quantity
              AppInput(
                label: 'Quantity',
                controller: _quantityController,
                required: true,
                hintText: 'e.g., 10',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                validator: validateQuantity,
              ),
              const SizedBox(height: 16),

              // Date picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Purchase Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(' *', style: TextStyle(color: AppColors.danger, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _purchaseDate != null
                                ? DateFormat('yyyy-MM-dd').format(_purchaseDate!)
                                : 'Select date',
                            style: TextStyle(
                              fontSize: 14,
                              color: _purchaseDate != null
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                          const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Info text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.cyan, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Investment data will be fetched automatically from Yahoo Finance.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Cancel',
                      variant: AppButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: 'Add Investment',
                      onPressed: _handleSubmit,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
