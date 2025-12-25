import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/model/payment_profile_model.dart';
import 'package:front/services/payment_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';

/// Screen for editing payment profile settings and payout methods
class EditPaymentProfileScreen extends StatefulWidget {
  final PaymentProfileModel? paymentProfile;

  const EditPaymentProfileScreen({super.key, this.paymentProfile});

  @override
  State<EditPaymentProfileScreen> createState() =>
      _EditPaymentProfileScreenState();
}

class _EditPaymentProfileScreenState extends State<EditPaymentProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _bankFormKey = GlobalKey<FormState>();

  // Profile settings controllers
  late TextEditingController _accountHolderNameController;
  late bool _autoPayoutEnabled;
  late int _minimumPayoutAmount;
  late String _payoutSchedule;

  // Bank account controllers
  final _accountNumberController = TextEditingController();
  final _routingNumberController = TextEditingController();
  final _bankAccountHolderNameController = TextEditingController();
  bool _isDefaultAccount = false;

  bool _isLoading = false;
  bool _isSavingSettings = false;
  bool _isAddingBank = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize with existing data or defaults
    _accountHolderNameController = TextEditingController(
      text: widget.paymentProfile?.accountDetails.accountHolderName ?? '',
    );
    _autoPayoutEnabled =
        widget.paymentProfile?.settings.autoPayoutEnabled ?? true;
    _minimumPayoutAmount =
        widget.paymentProfile?.settings.minimumPayoutAmount ?? 1000;
    _payoutSchedule =
        widget.paymentProfile?.settings.payoutSchedule ?? 'weekly';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _bankAccountHolderNameController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingSettings = true);

    try {
      await PaymentService.updatePaymentProfile(
        accountHolderName: _accountHolderNameController.text,
        autoPayoutEnabled: _autoPayoutEnabled,
        minimumPayoutAmount: _minimumPayoutAmount,
        payoutSchedule: _payoutSchedule,
      );

      if (mounted) {
        CustomSnackbars.showSuccessSnackbar(
          context,
          'Payment profile updated successfully',
          2.0,
        );
        Navigator.pop(context, true); // Return true to indicate changes
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to update profile: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingSettings = false);
      }
    }
  }

  Future<void> _addBankAccount() async {
    if (!_bankFormKey.currentState!.validate()) return;

    setState(() => _isAddingBank = true);

    try {
      await PaymentService.addPayoutMethod(
        accountNumber: _accountNumberController.text,
        routingNumber: _routingNumberController.text,
        accountHolderName: _bankAccountHolderNameController.text,
        isDefault: _isDefaultAccount,
      );

      if (mounted) {
        CustomSnackbars.showSuccessSnackbar(
          context,
          'Bank account added successfully',
          2.0,
        );

        // Clear form
        _accountNumberController.clear();
        _routingNumberController.clear();
        _bankAccountHolderNameController.clear();
        setState(() => _isDefaultAccount = false);

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to add bank account: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingBank = false);
      }
    }
  }

  Future<void> _removeBankAccount(String bankAccountId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Bank Account'),
        content: const Text(
          'Are you sure you want to remove this bank account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await PaymentService.removePayoutMethod(bankAccountId);

      if (mounted) {
        CustomSnackbars.showSuccessSnackbar(
          context,
          'Bank account removed successfully',
          2.0,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to remove bank account: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Payment Profile',
          style: TextStyle(color: AppColors.foregroundColor),
        ),
        backgroundColor: AppColors.appBarColor,
        bottom: TabBar(
          indicatorColor: AppColors.primary,
          labelColor: AppColors.foregroundColor,
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Settings',
              icon: Icon(Icons.settings, color: AppColors.foregroundColor),
            ),
            Tab(
              text: 'Payout Methods',
              icon: Icon(
                Icons.account_balance,
                color: AppColors.foregroundColor,
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSettingsTab(), _buildPayoutMethodsTab()],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Settings',
              style: TextStyle(
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Account Holder Name
            TextFormField(
              controller: _accountHolderNameController,
              decoration: const InputDecoration(
                labelText: 'Account Holder Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter account holder name';
                }
                return null;
              },
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Auto Payout Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Auto Payout'),
                subtitle: const Text('Automatically payout earnings'),
                value: _autoPayoutEnabled,
                onChanged: (value) {
                  setState(() => _autoPayoutEnabled = value);
                },
                secondary: const Icon(Icons.autorenew),
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Payout Schedule
            DropdownButtonFormField<String>(
              value: _payoutSchedule,
              decoration: const InputDecoration(
                labelText: 'Payout Schedule',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'manual', child: Text('Manual')),
              ],
              onChanged: (value) {
                setState(() => _payoutSchedule = value!);
              },
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Minimum Payout Amount
            TextFormField(
              initialValue: (_minimumPayoutAmount / 100).toStringAsFixed(2),
              decoration: const InputDecoration(
                labelText: 'Minimum Payout Amount (\$)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                helperText: 'Minimum amount before payout is triggered',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter minimum payout amount';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount < 1) {
                  return 'Amount must be at least \$1.00';
                }
                return null;
              },
              onChanged: (value) {
                final amount = double.tryParse(value);
                if (amount != null) {
                  _minimumPayoutAmount = (amount * 100).round();
                }
              },
            ),
            SizedBox(height: AppSizes.largeSpacing(context)),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSavingSettings ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: AppSizes.mediumPadding(context),
                  ),
                ),
                child: _isSavingSettings
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CustomWidgets.circularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutMethodsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payout Methods',
            style: TextStyle(
              fontSize: AppSizes.subtitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.smallSpacing(context)),
          Text(
            'Add a bank account to receive your earnings',
            style: TextStyle(
              fontSize: AppSizes.bodyFontSize(context),
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: AppSizes.mediumSpacing(context)),

          // Existing payout methods
          if (widget.paymentProfile != null &&
              widget.paymentProfile!.payoutMethods.isNotEmpty) ...[
            Card(
              child: Column(
                children: widget.paymentProfile!.payoutMethods.map((method) {
                  return ListTile(
                    leading: Icon(
                      Icons.account_balance,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      '${method.bankName ?? 'Bank'} •••• ${method.last4}',
                    ),
                    subtitle: Text(method.type.toUpperCase()),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (method.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _removeBankAccount(method.stripeBankAccountId!),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),
          ],

          // Add new bank account form
          Card(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
              child: Form(
                key: _bankFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Bank Account',
                      style: TextStyle(
                        fontSize: AppSizes.bodyFontSize(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    TextFormField(
                      controller: _bankAccountHolderNameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Holder Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    TextFormField(
                      controller: _routingNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Routing Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.route),
                        helperText: '9-digit routing number',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(9),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length != 9) {
                          return 'Must be 9 digits';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    TextFormField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Account Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.account_balance),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (value.length < 4) {
                          return 'Invalid account number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    CheckboxListTile(
                      value: _isDefaultAccount,
                      onChanged: (value) {
                        setState(() => _isDefaultAccount = value ?? false);
                      },
                      title: const Text('Set as default payout method'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    SizedBox(height: AppSizes.mediumSpacing(context)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isAddingBank ? null : _addBankAccount,
                        icon: _isAddingBank
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CustomWidgets.circularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: const Text('Add Bank Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: AppSizes.mediumPadding(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
