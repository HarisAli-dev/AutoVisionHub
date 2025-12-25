import 'package:flutter/material.dart';
import 'package:front/model/transaction_model.dart';
import 'package:front/services/payment_service.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/sizes.dart';
import 'package:front/utils/snackbars.dart';
import 'package:front/utils/time_utils.dart';

/// Screen for viewing transaction history
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isLoading = true;
  List<TransactionModel> _transactions = [];
  String? _filterType;
  String? _filterStatus;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
      });
    }

    try {
      final result = await PaymentService.getTransactionHistory(
        type: _filterType,
        status: _filterStatus,
        page: _currentPage,
      );

      if (result['success'] == true && mounted) {
        final List<dynamic> data = result['data'];
        final newTransactions = data
            .map((json) => TransactionModel.fromJson(json))
            .toList();

        setState(() {
          if (refresh) {
            _transactions = newTransactions;
          } else {
            _transactions.addAll(newTransactions);
          }
          _hasMore = newTransactions.length >= 50;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbars.showErrorSnackbar(
          context,
          'Failed to load transactions: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String?>(
              value: _filterType,
              decoration: const InputDecoration(
                labelText: 'Transaction Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(
                  value: 'event_booking',
                  child: Text('Event Booking'),
                ),
                DropdownMenuItem(
                  value: 'marketplace_purchase',
                  child: Text('Marketplace Purchase'),
                ),
                DropdownMenuItem(
                  value: 'marketplace_bid',
                  child: Text('Marketplace Bid'),
                ),
              ],
              onChanged: (value) {
                setState(() => _filterType = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              value: _filterStatus,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'failed', child: Text('Failed')),
              ],
              onChanged: (value) {
                setState(() => _filterStatus = value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterType = null;
                _filterStatus = null;
              });
              Navigator.pop(context);
              _loadTransactions(refresh: true);
            },
            child: const Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadTransactions(refresh: true);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transaction History',
          style: TextStyle(color: AppColors.foregroundColor),
        ),
        backgroundColor: AppColors.appBarColor,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: AppColors.foregroundColor),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.foregroundColor),
            onPressed: () => _loadTransactions(refresh: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading && _transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
          ? _buildEmptyState()
          : _buildTransactionList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          SizedBox(height: AppSizes.mediumSpacing(context)),
          Text(
            'No Transactions',
            style: TextStyle(
              fontSize: AppSizes.subtitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSizes.smallSpacing(context)),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(
              fontSize: AppSizes.bodyFontSize(context),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return RefreshIndicator(
      onRefresh: () => _loadTransactions(refresh: true),
      child: ListView.builder(
        padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
        itemCount: _transactions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _transactions.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _currentPage++);
                    _loadTransactions();
                  },
                  child: const Text('Load More'),
                ),
              ),
            );
          }

          return _buildTransactionCard(_transactions[index]);
        },
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isReceived = transaction.toUser != null;
    final statusColor = _getStatusColor(transaction.status);

    return Card(
      margin: EdgeInsets.only(bottom: AppSizes.mediumSpacing(context)),
      child: InkWell(
        onTap: () => _showTransactionDetails(transaction),
        child: Padding(
          padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      transaction.getTransactionTypeLabel(),
                      style: TextStyle(
                        fontSize: AppSizes.bodyFontSize(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${isReceived ? '+' : '-'}${PaymentService.formatAmount(isReceived ? transaction.netAmount : transaction.amount)}',
                    style: TextStyle(
                      fontSize: AppSizes.bodyFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: isReceived ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.smallSpacing(context)),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.getStatusLabel(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: AppSizes.smallFontSize(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(transaction.createdAt),
                    style: TextStyle(
                      fontSize: AppSizes.smallFontSize(context),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (transaction.description != null) ...[
                SizedBox(height: AppSizes.smallSpacing(context)),
                Text(
                  transaction.description!,
                  style: TextStyle(
                    fontSize: AppSizes.smallFontSize(context),
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    final isReceived = transaction.toUser != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(AppSizes.mediumPadding(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),
              Text(
                'Transaction Details',
                style: TextStyle(
                  fontSize: AppSizes.titleFontSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: AppSizes.mediumSpacing(context)),
              _buildDetailRow('Type', transaction.getTransactionTypeLabel()),
              _buildDetailRow('Status', transaction.getStatusLabel()),
              _buildDetailRow(
                'Amount',
                PaymentService.formatAmount(transaction.amount),
              ),
              if (isReceived) ...[
                _buildDetailRow(
                  'Platform Fee',
                  PaymentService.formatAmount(transaction.platformFee),
                ),
                _buildDetailRow(
                  'You Received',
                  PaymentService.formatAmount(transaction.netAmount),
                ),
              ],
              _buildDetailRow('Currency', transaction.currency.toUpperCase()),
              _buildDetailRow('Date', _formatDate(transaction.createdAt)),
              if (transaction.description != null)
                _buildDetailRow('Description', transaction.description!),
              if (transaction.fromUser != null)
                _buildDetailRow('From', transaction.fromUser!['name']),
              if (transaction.toUser != null)
                _buildDetailRow('To', transaction.toUser!['name']),
              if (transaction.stripePaymentIntentId != null)
                _buildDetailRow(
                  'Payment ID',
                  transaction.stripePaymentIntentId!.substring(0, 20) + '...',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSizes.smallPadding(context)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.bodyFontSize(context),
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.bodyFontSize(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return TimeUtils.formatDateTimePKT(date);
  }
}
