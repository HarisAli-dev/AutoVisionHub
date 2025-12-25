import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:front/model/payment_profile_model.dart';
import 'package:front/services/payment_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/custom_widgets.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/view/payment/edit_payment_profile_screen.dart';
import 'package:front/view/payment/transaction_history_screen.dart';

/// Payment Profile Screen for managing payment settings
class PaymentProfileScreen extends StatefulWidget {
  const PaymentProfileScreen({super.key});

  @override
  State<PaymentProfileScreen> createState() => _PaymentProfileScreenState();
}

class _PaymentProfileScreenState extends State<PaymentProfileScreen> {
  bool _isLoading = true;
  bool _hasProfile = false;
  PaymentProfileModel? _paymentProfile;
  Map<String, dynamic>? _stripeAccount;
  List<dynamic>? _balance;

  @override
  void initState() {
    super.initState();
    _loadPaymentProfile();
  }

  Future<void> _loadPaymentProfile() async {
    setState(() => _isLoading = true);

    try {
      final result = await PaymentService.getPaymentProfile();

      if (result['success'] == true && mounted) {
        final data = result['data'];
        if (data != null && data['paymentProfile'] != null) {
          setState(() {
            _hasProfile = true;
            _paymentProfile = PaymentProfileModel.fromJson(
              data['paymentProfile'],
            );
            _stripeAccount = data['stripeAccount'] as Map<String, dynamic>?;
            _balance = data['balance'] as List?;
          });
        } else {
          setState(() => _hasProfile = false);
        }
      } else {
        setState(() => _hasProfile = false);
      }
    } catch (e, stackTrace) {
      print('Error loading payment profile: $e $stackTrace');
      if (mounted) {
        setState(() => _hasProfile = false);
        // Show error snackbar only if it's not a "not found" error
        if (!e.toString().contains('404') &&
            !e.toString().contains('not found')) {
          CustomSnackbars.showErrorSnackbar(
            context,
            'Failed to load payment profile. Please try again.',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createPaymentProfile() async {
    // Show creation dialog
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const _CreateProfileDialog(),
    );

    if (result == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await PaymentService.createPaymentProfile(
        country: result['country']!,
        currency: result['currency']!,
        accountHolderName: result['accountHolderName']!,
        accountHolderType: result['accountHolderType']!,
      );

      if (response['success'] == true && mounted) {
        // Get onboarding URL and launch
        final onboardingUrl = response['data']['onboardingUrl'];
        if (onboardingUrl != null) {
          await _launchUrl(onboardingUrl);
        }

        CustomSnackbars.showSuccessSnackbar(
          context,
          'Payment profile created! Complete the onboarding process.',
          3.0,
        );

        _loadPaymentProfile();
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error creating payment profile: $e');
        // Check if profile already exists
        if (e.toString().contains('already exists')) {
          CustomSnackbars.showInfoSnackbar(
            context,
            'Payment profile already exists. Refreshing...',
            3.0,
          );
          _loadPaymentProfile();
        } else {
          CustomSnackbars.showErrorSnackbar(
            context,
            'Failed to create payment profile: ${e.toString().replaceAll('Exception: Error creating payment profile: Exception: ', '')}',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final url = await PaymentService.generateOnboardingLink();
      await _launchUrl(url);

      CustomSnackbars.showInfoSnackbar(
        context,
        'Complete the Stripe onboarding process',
        3.0,
      );
    } catch (e, stackTrace) {
      debugPrint('Error generating onboarding link: $e $stackTrace');
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to generate onboarding link: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    // Copy URL to clipboard for user to open manually
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      CustomSnackbars.showInfoSnackbar(
        context,
        'Onboarding URL copied to clipboard. Please open it in your browser.',
        5.0,
      );
    }
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditPaymentProfileScreen(paymentProfile: _paymentProfile),
      ),
    ).then((_) => _loadPaymentProfile());
  }

  void _navigateToTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Payment Profile',
          style: TextStyle(color: AppColors.foregroundColor),
        ),
        backgroundColor: AppColors.appBarColor,
        actions: [
          if (_hasProfile && _paymentProfile != null)
            IconButton(
              icon: Icon(Icons.edit, color: AppColors.foregroundColor),
              onPressed: _navigateToEditProfile,
              tooltip: 'Edit Profile',
            ),
          if (_hasProfile)
            IconButton(
              icon: Icon(Icons.history, color: AppColors.foregroundColor),
              onPressed: _navigateToTransactionHistory,
              tooltip: 'Transaction History',
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.foregroundColor),
            onPressed: _loadPaymentProfile,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CustomWidgets.circularProgressIndicator())
          : _hasProfile
          ? _buildProfileView()
          : _buildCreateProfileView(),
    );
  }

  Widget _buildProfileView() {
    if (_paymentProfile == null) {
      return const Center(child: Text('Failed to load profile'));
    }

    final profile = _paymentProfile!;
    final isVerified = _stripeAccount?['detailsSubmitted'] == true;
    final canReceivePayments = _stripeAccount?['chargesEnabled'] == true;

    return RefreshIndicator(
      onRefresh: _loadPaymentProfile,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Status Card
            _buildAccountStatusCard(profile, isVerified, canReceivePayments),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Balance Card
            _buildBalanceCard(profile),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Statistics Card
            _buildStatisticsCard(profile),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Payout Methods
            _buildPayoutMethodsCard(profile),
            SizedBox(height: AppSizes.mediumSpacing(context)),

            // Settings
            _buildSettingsCard(profile),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStatusCard(
    PaymentProfileModel profile,
    bool isVerified,
    bool canReceivePayments,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isVerified ? Icons.verified : Icons.pending,
                  color: isVerified ? Colors.green : Colors.orange,
                  size: 32,
                ),
                SizedBox(width: AppSizes.smallPadding(context)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.accountDetails.accountHolderName,
                        style: TextStyle(
                          fontSize: AppSizes.subtitleFontSize(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isVerified
                            ? 'Account Verified'
                            : 'Verification Pending',
                        style: TextStyle(
                          color: isVerified ? Colors.green : Colors.orange,
                          fontSize: AppSizes.bodyFontSize(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),
            _buildInfoRow(
              'Account Type',
              profile.accountDetails.accountHolderType.toUpperCase(),
            ),
            _buildInfoRow('Country', profile.accountDetails.country),
            _buildInfoRow(
              'Currency',
              profile.accountDetails.currency.toUpperCase(),
            ),
            _buildInfoRow('Status', profile.accountStatus.toUpperCase()),
            _buildInfoRow(
              'Can Receive Payments',
              canReceivePayments ? 'Yes' : 'No',
              valueColor: canReceivePayments ? Colors.green : Colors.red,
            ),
            if (!isVerified) ...[
              SizedBox(height: AppSizes.mediumSpacing(context)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _continueOnboarding,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Complete Verification'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(PaymentProfileModel profile) {
    double availableBalance = 0;
    try {
      if (_balance != null && _balance!.isNotEmpty) {
        final firstBalance = _balance!.first;
        if (firstBalance is Map<String, dynamic>) {
          availableBalance = ((firstBalance['amount'] ?? 0) as num).toDouble();
        }
      }
    } catch (e) {
      print('Error parsing balance: $e');
      availableBalance = 0;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance',
              style: TextStyle(
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.smallSpacing(context)),
            Text(
              PaymentService.formatAmount(availableBalance),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Available Balance',
              style: TextStyle(
                fontSize: AppSizes.bodyFontSize(context),
                color: Colors.grey,
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),
            _buildInfoRow(
              'Pending Balance',
              PaymentService.formatAmount(profile.statistics.pendingBalance),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(PaymentProfileModel profile) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings Summary',
              style: TextStyle(
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),
            _buildInfoRow(
              'Total Earnings',
              PaymentService.formatAmount(profile.statistics.totalEarnings),
            ),
            _buildInfoRow(
              'Total Transactions',
              profile.statistics.transactionCount.toString(),
            ),
            _buildInfoRow(
              'Last Payout',
              profile.statistics.lastPayoutDate != null
                  ? '${profile.statistics.lastPayoutDate!.day}/${profile.statistics.lastPayoutDate!.month}/${profile.statistics.lastPayoutDate!.year}'
                  : 'No payouts yet',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutMethodsCard(PaymentProfileModel profile) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Payout Methods',
                  style: TextStyle(
                    fontSize: AppSizes.subtitleFontSize(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _navigateToEditProfile,
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  label: const Text(
                    'Add',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.smallSpacing(context)),
            if (profile.payoutMethods.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                  child: Text(
                    'No payout methods added',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: AppSizes.bodyFontSize(context),
                    ),
                  ),
                ),
              )
            else
              ...profile.payoutMethods.map((method) {
                return ListTile(
                  leading: Icon(
                    Icons.account_balance,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    '${method.bankName ?? 'Bank'} •••• ${method.last4}',
                  ),
                  subtitle: Text(method.type.toUpperCase()),
                  trailing: method.isDefault
                      ? Container(
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
                        )
                      : null,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(PaymentProfileModel profile) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: AppSizes.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),
            _buildInfoRow(
              'Auto Payout',
              profile.settings.autoPayoutEnabled ? 'Enabled' : 'Disabled',
              valueColor: profile.settings.autoPayoutEnabled
                  ? Colors.green
                  : Colors.grey,
            ),
            _buildInfoRow(
              'Payout Schedule',
              profile.settings.payoutSchedule.toUpperCase(),
            ),
            _buildInfoRow(
              'Minimum Payout',
              PaymentService.formatAmount(
                profile.settings.minimumPayoutAmount.toDouble(),
              ),
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _navigateToEditProfile,
                child: const Text(
                  'Edit Settings',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.bodyFontSize(context),
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.bodyFontSize(context),
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateProfileView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.largePadding(context)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 100,
              color: Colors.grey[400],
            ),
            SizedBox(height: AppSizes.mediumSpacing(context)),
            Text(
              'No Payment Profile',
              style: TextStyle(
                fontSize: AppSizes.titleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.smallSpacing(context)),
            Text(
              'Create a payment profile to receive payments for your services',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.bodyFontSize(context),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: AppSizes.largeSpacing(context)),
            ElevatedButton.icon(
              onPressed: _createPaymentProfile,
              icon: const Icon(Icons.add),
              label: const Text('Create Payment Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.largePadding(context),
                  vertical: AppSizes.mediumPadding(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for creating a payment profile
class _CreateProfileDialog extends StatefulWidget {
  const _CreateProfileDialog();

  @override
  State<_CreateProfileDialog> createState() => _CreateProfileDialogState();
}

class _CreateProfileDialogState extends State<_CreateProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _country = 'US';
  String _currency = 'usd';
  String _accountType = 'individual';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Payment Profile'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account holder name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _country,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'US', child: Text('United States')),
                  DropdownMenuItem(value: 'GB', child: Text('United Kingdom')),
                  DropdownMenuItem(value: 'CA', child: Text('Canada')),
                  DropdownMenuItem(value: 'AU', child: Text('Australia')),
                ],
                onChanged: (value) {
                  setState(() => _country = value!);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(
                  labelText: 'Currency',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'usd', child: Text('USD')),
                  DropdownMenuItem(value: 'gbp', child: Text('GBP')),
                  DropdownMenuItem(value: 'cad', child: Text('CAD')),
                  DropdownMenuItem(value: 'aud', child: Text('AUD')),
                ],
                onChanged: (value) {
                  setState(() => _currency = value!);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _accountType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'individual',
                    child: Text('Individual'),
                  ),
                  DropdownMenuItem(value: 'company', child: Text('Company')),
                ],
                onChanged: (value) {
                  setState(() => _accountType = value!);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'accountHolderName': _nameController.text,
                'country': _country,
                'currency': _currency,
                'accountHolderType': _accountType,
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
