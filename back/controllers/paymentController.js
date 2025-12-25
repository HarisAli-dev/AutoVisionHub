const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const PaymentProfile = require('../models/paymentProfileModel');
const Transaction = require('../models/transactionModel');
const User = require('../models/users/userModel');

// Platform fee percentage (your commission)
const PLATFORM_FEE_PERCENTAGE = 5; // 5% platform fee

// Helper function to ensure URL has proper protocol
const formatFrontendUrl = (path) => {
  let baseUrl = process.env.FRONTEND_URL || 'http://localhost:3000';
  // Add protocol if missing
  if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
    baseUrl = `https://${baseUrl}`;
  }
  // Remove trailing slash
  baseUrl = baseUrl.replace(/\/$/, '');
  return `${baseUrl}${path}`;
};

/**
 * Create or update payment profile with Stripe Connect
 */
exports.createPaymentProfile = async (req, res) => {
  try {
    const userId = req.user._id;
    const {
      country,
      currency,
      accountHolderName,
      accountHolderType,
      email,
      businessType
    } = req.body;

    // Check if profile already exists
    let existingProfile = await PaymentProfile.findOne({ userId });
    if (existingProfile) {
      return res.status(400).json({ 
        success: false,
        message: 'Payment profile already exists. Use update endpoint instead.' 
      });
    }

    // Get user details
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Create Stripe Connect Account (Express or Standard)
    const account = await stripe.accounts.create({
      type: 'express', // or 'standard' for more control
      country: country || 'US',
      email: email || user.email,
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true },
      },
      business_type: businessType || 'individual',
      metadata: {
        userId: userId.toString(),
        userName: user.name,
        userRole: user.role
      }
    });

    // Create payment profile in database
    const paymentProfile = new PaymentProfile({
      userId,
      stripeAccountId: account.id,
      accountStatus: 'pending',
      accountDetails: {
        country: country || 'US',
        currency: currency || 'usd',
        accountHolderName: accountHolderName || user.name,
        accountHolderType: accountHolderType || 'individual'
      }
    });

    await paymentProfile.save();

    // Create account link for onboarding
    const accountLink = await stripe.accountLinks.create({
      account: account.id,
      refresh_url: formatFrontendUrl('/payment-profile/refresh'),
      return_url: formatFrontendUrl('/payment-profile/success'),
      type: 'account_onboarding',
    });

    res.status(201).json({
      success: true,
      message: 'Payment profile created successfully',
      data: {
        paymentProfile,
        onboardingUrl: accountLink.url
      }
    });
  } catch (error) {
    console.error('Error creating payment profile:', error);
    res.status(500).json({ 
      success: false,
      message: 'Failed to create payment profile',
      error: error.message 
    });
  }
};

/**
 * Get payment profile for current user
 */
exports.getPaymentProfile = async (req, res) => {
  try {
    const userId = req.user._id;

    const paymentProfile = await PaymentProfile.findOne({ userId });

    if (!paymentProfile) {
      return res.status(404).json({ 
        success: false,
        message: 'Payment profile not found' 
      });
    }

    // Get Stripe account details
    const account = await stripe.accounts.retrieve(paymentProfile.stripeAccountId);

    // Get account balance
    const balance = await stripe.balance.retrieve({
      stripeAccount: paymentProfile.stripeAccountId
    });

    res.json({
      success: true,
      data: {
        paymentProfile,
        stripeAccount: {
          chargesEnabled: account.charges_enabled,
          payoutsEnabled: account.payouts_enabled,
          detailsSubmitted: account.details_submitted,
          requirements: account.requirements
        },
        balance: balance.available
      }
    });
  } catch (error) {
    console.error('Error getting payment profile:', error);
    res.status(500).json({ 
      success: false,
      message: 'Failed to get payment profile',
      error: error.message 
    });
  }
};

/**
 * Update payment profile
 */
exports.updatePaymentProfile = async (req, res) => {
  try {
    const userId = req.user._id;
    const {
      accountHolderName,
      autoPayoutEnabled,
      minimumPayoutAmount,
      payoutSchedule
    } = req.body;

    const paymentProfile = await PaymentProfile.findOne({ userId });
    if (!paymentProfile) {
      return res.status(404).json({ 
        success: false,
        message: 'Payment profile not found' 
      });
    }

    // Update fields
    if (accountHolderName) {
      paymentProfile.accountDetails.accountHolderName = accountHolderName;
    }
    if (autoPayoutEnabled !== undefined) {
      paymentProfile.settings.autoPayoutEnabled = autoPayoutEnabled;
    }
    if (minimumPayoutAmount) {
      paymentProfile.settings.minimumPayoutAmount = minimumPayoutAmount;
    }
    if (payoutSchedule) {
      paymentProfile.settings.payoutSchedule = payoutSchedule;
    }

    paymentProfile.lastUpdated = Date.now();
    await paymentProfile.save();

    res.json({
      success: true,
      message: 'Payment profile updated successfully',
      data: paymentProfile
    });
  } catch (error) {
    console.error('Error updating payment profile:', error);
    res.status(500).json({ 
      success: false,
      message: 'Failed to update payment profile',
      error: error.message 
    });
  }
};

/**
 * Add payout method (bank account)
 */
exports.addPayoutMethod = async (req, res) => {
  try {
    const userId = req.user._id;
    const { accountNumber, routingNumber, accountHolderName, isDefault } = req.body;

    const paymentProfile = await PaymentProfile.findOne({ userId });
    if (!paymentProfile) {
      return res.status(404).json({ 
        success: false,
        message: 'Payment profile not found. Create a payment profile first.' 
      });
    }

    // Create external account (bank account) in Stripe
    const bankAccount = await stripe.accounts.createExternalAccount(
      paymentProfile.stripeAccountId,
      {
        external_account: {
          object: 'bank_account',
          country: paymentProfile.accountDetails.country,
          currency: paymentProfile.accountDetails.currency,
          account_number: accountNumber,
          routing_number: routingNumber,
          account_holder_name: accountHolderName || paymentProfile.accountDetails.accountHolderName
        }
      }
    );

    // Set as default if requested
    if (isDefault) {
      await stripe.accounts.updateExternalAccount(
        paymentProfile.stripeAccountId,
        bankAccount.id,
        { default_for_currency: true }
      );
      
      // Update all other methods to not be default
      paymentProfile.payoutMethods.forEach(method => {
        method.isDefault = false;
      });
    }

    // Add to payment profile
    paymentProfile.payoutMethods.push({
      type: 'bank_account',
      last4: bankAccount.last4,
      bankName: bankAccount.bank_name,
      isDefault: isDefault || paymentProfile.payoutMethods.length === 0,
      stripeBankAccountId: bankAccount.id
    });

    await paymentProfile.save();

    res.json({
      success: true,
      message: 'Payout method added successfully',
      data: paymentProfile
    });
  } catch (error) {
    console.error('Error adding payout method:', error);
    res.status(500).json({ 
      success: false,
      message: 'Failed to add payout method',
      error: error.message 
    });
  }
};

/**
 * Remove payout method
 */
exports.removePayoutMethod = async (req, res) => {
  try {
    const userId = req.user._id;
    const { bankAccountId } = req.params;

    const paymentProfile = await PaymentProfile.findOne({ userId });
    if (!paymentProfile) {
      return res.status(404).json({ 
        success: false,
        message: 'Payment profile not found' 
      });
    }

    // Find the payout method
    const methodIndex = paymentProfile.payoutMethods.findIndex(
      method => method.stripeBankAccountId === bankAccountId
    );

    if (methodIndex === -1) {
      return res.status(404).json({ 
        success: false,
        message: 'Payout method not found' 
      });
    }

    // Delete from Stripe
    await stripe.accounts.deleteExternalAccount(
      paymentProfile.stripeAccountId,
      bankAccountId
    );

    // Remove from profile
    paymentProfile.payoutMethods.splice(methodIndex, 1);
    await paymentProfile.save();

    res.json({
      success: true,
      message: 'Payout method removed successfully',
      data: paymentProfile
    });
  } catch (error) {
    console.error('Error removing payout method:', error);
    res.status(500).json({ 
      success: false,
      message: 'Failed to remove payout method',
      error: error.message 
    });
  }
};

/**
 * Generate new onboarding link
 */
exports.generateOnboardingLink = async (req, res) => {
  try {
    const userId = req.user._id;

    const paymentProfile = await PaymentProfile.findOne({ userId });
    if (!paymentProfile) {
      return res.status(404).json({ 
        success: false,
        message: 'Payment profile not found' 
      });
    }

    const accountLink = await stripe.accountLinks.create({
      account: paymentProfile.stripeAccountId,
      refresh_url: formatFrontendUrl('/payment-profile/refresh'),
      return_url: formatFrontendUrl('/payment-profile/success'),
      type: 'account_onboarding',
    });

    res.json({
      success: true,
      data: {
        onboardingUrl: accountLink.url
      }
    });
  } catch (error) {
    console.error('Error generating onboarding link:', error);
    res.status(500).json({ 
      success: false,
      message: 'Failed to generate onboarding link',
      error: error.message 
    });
  }
};

/**
 * Create payment intent (existing function with improvements)
 */
exports.createPaymentIntent = async (req, res) => {
  try {
    const { amount, currency, recipientUserId, transactionType, relatedEntityId, description } = req.body;
    const fromUserId = req.user._id;

    // Validate recipient has payment profile
    const recipientProfile = await PaymentProfile.findOne({ 
      userId: recipientUserId,
      isActive: true 
    });

    if (!recipientProfile) {
      return res.status(400).json({ 
        success: false,
        message: 'Recipient does not have an active payment profile' 
      });
    }

    if (!recipientProfile.verification.isVerified) {
      return res.status(400).json({ 
        success: false,
        message: 'Recipient payment profile is not verified' 
      });
    }

    // Calculate platform fee
    const platformFee = Math.round(amount * (PLATFORM_FEE_PERCENTAGE / 100));
    const netAmount = amount - platformFee;

    // Create payment intent with automatic transfer to connected account
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency || 'usd',
      application_fee_amount: platformFee,
      transfer_data: {
        destination: recipientProfile.stripeAccountId,
      },
      metadata: {
        fromUserId: fromUserId.toString(),
        toUserId: recipientUserId.toString(),
        transactionType,
        relatedEntityId: relatedEntityId?.toString(),
        platformFee,
        netAmount
      },
      description: description || 'Payment via Community Hub'
    });

    // Create transaction record
    const transaction = new Transaction({
      fromUserId,
      toUserId: recipientUserId,
      transactionType,
      relatedEntityId,
      relatedEntityType: req.body.relatedEntityType || 'Other',
      amount,
      currency: currency || 'usd',
      platformFee,
      platformFeePercentage: PLATFORM_FEE_PERCENTAGE,
      netAmount,
      stripePaymentIntentId: paymentIntent.id,
      status: 'pending',
      description
    });

    await transaction.save();

    res.json({ 
      success: true,
      clientSecret: paymentIntent.client_secret,
      transactionId: transaction._id
    });
  } catch (error) {
    console.error('Error creating payment intent:', error);
    res.status(500).json({ 
      success: false,
      message: 'Failed to create payment intent',
      error: error.message 
    });
  }
};

/**
 * Get transaction history for user
 */
exports.getTransactionHistory = async (req, res) => {
  try {
    const userId = req.user._id;
    const { type, status, limit = 50, page = 1 } = req.query;

    const query = {
      $or: [
        { fromUserId: userId },
        { toUserId: userId }
      ]
    };

    if (type) query.transactionType = type;
    if (status) query.status = status;

    const transactions = await Transaction.find(query)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip((parseInt(page) - 1) * parseInt(limit))
      .populate('fromUserId', 'name email')
      .populate('toUserId', 'name email');

    const total = await Transaction.countDocuments(query);

    res.json({
      success: true,
      data: transactions,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Error getting transaction history:', error);
    res.status(500).json({ 
      success: false,
      message: 'Failed to get transaction history',
      error: error.message 
    });
  }
};

/**
 * Get earnings summary
 */
exports.getEarningsSummary = async (req, res) => {
  try {
    const userId = req.user._id;

    const paymentProfile = await PaymentProfile.findOne({ userId });
    if (!paymentProfile) {
      return res.status(404).json({ 
        success: false,
        message: 'Payment profile not found' 
      });
    }

    // Get total earnings
    const earnings = await Transaction.aggregate([
      {
        $match: {
          toUserId: userId,
          status: 'completed'
        }
      },
      {
        $group: {
          _id: null,
          totalEarnings: { $sum: '$netAmount' },
          totalTransactions: { $sum: 1 }
        }
      }
    ]);

    // Get pending balance
    const pending = await Transaction.aggregate([
      {
        $match: {
          toUserId: userId,
          status: { $in: ['pending', 'processing'] }
        }
      },
      {
        $group: {
          _id: null,
          pendingAmount: { $sum: '$netAmount' }
        }
      }
    ]);

    res.json({
      success: true,
      data: {
        totalEarnings: earnings[0]?.totalEarnings || 0,
        totalTransactions: earnings[0]?.totalTransactions || 0,
        pendingBalance: pending[0]?.pendingAmount || 0,
        statistics: paymentProfile.statistics
      }
    });
  } catch (error) {
    console.error('Error getting earnings summary:', error);
    res.status(500).json({ 
      success: false,
      message: 'Failed to get earnings summary',
      error: error.message 
    });
  }
};

/**
 * Webhook handler for Stripe events
 */
exports.handleStripeWebhook = async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event;

  try {
    event = stripe.webhooks.constructEvent(
      req.body,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET
    );
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  try {
    // Handle the event
    switch (event.type) {
      case 'payment_intent.succeeded':
        await handlePaymentSuccess(event.data.object);
        break;
      case 'payment_intent.payment_failed':
        await handlePaymentFailure(event.data.object);
        break;
      case 'account.updated':
        await handleAccountUpdate(event.data.object);
        break;
      case 'transfer.created':
        await handleTransferCreated(event.data.object);
        break;
      default:
        console.log(`Unhandled event type ${event.type}`);
    }

    res.json({ received: true });
  } catch (error) {
    console.error('Error handling webhook:', error);
    res.status(500).json({ error: 'Webhook handler failed' });
  }
};

// Helper functions for webhook handlers
async function handlePaymentSuccess(paymentIntent) {
  const transaction = await Transaction.findOne({ 
    stripePaymentIntentId: paymentIntent.id 
  });

  if (transaction) {
    transaction.status = 'completed';
    transaction.paymentStatus = 'captured';
    transaction.paymentDate = new Date();
    transaction.completedAt = new Date();
    await transaction.save();

    // Update recipient's payment profile statistics
    const recipientProfile = await PaymentProfile.findOne({ 
      userId: transaction.toUserId 
    });
    if (recipientProfile) {
      recipientProfile.statistics.totalEarnings += transaction.netAmount;
      recipientProfile.statistics.transactionCount += 1;
      await recipientProfile.save();
    }
  }
}

async function handlePaymentFailure(paymentIntent) {
  const transaction = await Transaction.findOne({ 
    stripePaymentIntentId: paymentIntent.id 
  });

  if (transaction) {
    transaction.status = 'failed';
    transaction.paymentStatus = 'failed';
    transaction.errorMessage = paymentIntent.last_payment_error?.message;
    await transaction.save();
  }
}

async function handleAccountUpdate(account) {
  const paymentProfile = await PaymentProfile.findOne({ 
    stripeAccountId: account.id 
  });

  if (paymentProfile) {
    paymentProfile.verification.isVerified = account.charges_enabled && account.payouts_enabled;
    paymentProfile.verification.documentsSubmitted = account.details_submitted;
    paymentProfile.accountStatus = account.charges_enabled ? 'active' : 'pending';
    
    if (paymentProfile.verification.isVerified && !paymentProfile.verification.verifiedAt) {
      paymentProfile.verification.verifiedAt = new Date();
    }
    
    await paymentProfile.save();
  }
}

async function handleTransferCreated(transfer) {
  // Update transaction with transfer ID
  const transaction = await Transaction.findOne({
    stripePaymentIntentId: transfer.source_transaction
  });

  if (transaction) {
    transaction.stripeTransferId = transfer.id;
    transaction.payoutStatus = 'in_transit';
    await transaction.save();
  }
}