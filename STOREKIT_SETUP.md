# StoreKit Integration Setup Guide

This guide will help you configure StoreKit in the Embrace E-Commerce sample app to demonstrate how StoreKit telemetry appears in the Embrace dashboard.

## Overview

The app includes a comprehensive StoreKit 2 implementation with full Embrace telemetry integration. This allows you to:
- Track product loading performance
- Monitor purchase flows and completion rates
- Capture transaction verification events
- Log purchase errors and failures
- Track restore purchase operations

## Quick Start (For Testing)

### 1. Add StoreKit Configuration File to Xcode

The `Configuration.storekit` file has been created in the project directory. To use it:

1. Open the project in Xcode
2. In Project Navigator, find `Configuration.storekit`
3. Select the file and ensure it's included in your target membership
4. In Xcode menu, go to **Editor → Default StoreKit Configuration**
5. Select `Configuration.storekit`

This enables local testing without connecting to App Store Connect.

### 2. Enable In-App Purchase Capability

1. In Xcode, select your project in the navigator
2. Select your app target
3. Go to the **Signing & Capabilities** tab
4. Click **+ Capability**
5. Add **In-App Purchase**

### 3. Run and Test

You can now run the app and test StoreKit purchases:

1. Launch the app in the simulator or on a device
2. Add items to your cart
3. Proceed to checkout
4. Select **"StoreKit Payment"** as the payment method
5. Choose a product from the list
6. Complete the purchase flow

The StoreKit Configuration file provides these test products:
- **Single Item** ($9.99) - For small purchases
- **Small Cart** ($29.99) - For 2-3 items
- **Medium Cart** ($49.99) - For 4-6 items
- **Large Cart** ($99.99) - For 7+ items
- **Premium Shipping** ($4.99) - Upgrade option
- **Tip** ($0.99) - Gratuity option

## For Customers: Using Your Own Products

To demonstrate StoreKit with your actual App Store Connect products:

### 1. Update Configuration.storekit

Edit `Configuration.storekit` and replace the product IDs with your own:

```json
{
  "products": [
    {
      "displayPrice": "9.99",
      "productID": "com.yourcompany.yourapp.product_id",
      "referenceName": "Your Product Name",
      "type": "Consumable",
      "localizations": [
        {
          "description": "Your product description",
          "displayName": "Display Name",
          "locale": "en_US"
        }
      ]
    }
  ],
  "settings": {
    "_developerTeamID": "YOUR_TEAM_ID"
  }
}
```

### 2. Update Product IDs in Code

Open `Embrace Ecommerce/Services/StoreKitManager.swift` and update the `ProductID` enum:

```swift
enum ProductID: String, CaseIterable {
    case yourProduct = "com.yourcompany.yourapp.product_id"
    // Add more products as needed

    var displayName: String {
        switch self {
        case .yourProduct: return "Your Product"
        }
    }
}
```

### 3. Configure App Store Connect

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Go to **Features → In-App Purchases**
4. Create in-app purchases matching your product IDs
5. Ensure products are in "Ready to Submit" status

### 4. Test with Sandbox Testers

1. In App Store Connect, create sandbox test accounts
2. On your test device, sign out of the App Store
3. When prompted during purchase, sign in with sandbox account
4. Complete test purchases

## StoreKit Telemetry in Embrace

The integration captures comprehensive telemetry:

### Product Loading
- **Span**: `storekit_load_products`
- **Attributes**:
  - `storekit.products_loaded` - Number of products fetched
  - `storekit.duration_ms` - Load time in milliseconds
  - `storekit.status` - Success or error status

### Purchase Flow
- **Span**: `storekit_purchase`
- **Attributes**:
  - `storekit.product_id` - Product being purchased
  - `storekit.product_name` - Product display name
  - `storekit.price` - Formatted price string
  - `storekit.transaction_id` - Transaction ID (on success)
  - `storekit.status` - success, user_cancelled, pending, or error
  - `storekit.duration_ms` - Purchase flow duration

### Transaction Verification
- **Span**: `storekit_verify_transaction`
- **Attributes**:
  - `storekit.verification_status` - verified or failed
  - `storekit.verification_error` - Error details if failed

### Transaction Updates
- **Span**: `storekit_transaction_update`
- **Attributes**:
  - `storekit.transaction_id` - Transaction identifier
  - `storekit.product_id` - Product identifier
  - `storekit.purchase_date` - ISO 8601 timestamp
  - `storekit.revocation_date` - If transaction was revoked

### Restore Purchases
- **Span**: `storekit_restore_purchases`
- **Attributes**:
  - `storekit.restored_count` - Number of transactions restored
  - `storekit.duration_ms` - Restore operation duration

### Breadcrumbs

The implementation adds breadcrumbs throughout the flow:
- `StoreKit manager initialized`
- `Loading StoreKit products`
- `Loaded X StoreKit products`
- `StoreKit purchase initiated: [Product Name]`
- `StoreKit purchase completed: [Product Name]`
- `StoreKit purchase cancelled: [Product Name]`
- `STOREKIT_PAYMENT_INITIATED`
- `STOREKIT_PAYMENT_SUCCESS`
- `STOREKIT_PAYMENT_CANCELLED`
- `STOREKIT_PAYMENT_ERROR`

### Logs

Comprehensive logging at different severity levels:
- **Info**: Successful operations, status updates
- **Warning**: User cancellations, pending transactions
- **Error**: Purchase failures, verification errors, product loading errors

## Testing Scenarios

### Happy Path
1. User selects StoreKit payment
2. Products load successfully
3. User selects a product
4. Purchase completes successfully
5. Transaction is verified
6. Order is placed

**Expected Embrace Events**:
- Product load span (success)
- Purchase span (success)
- Verification span (verified)
- Transaction update span
- Multiple breadcrumbs tracking the flow
- Info logs for each step

### User Cancellation
1. User selects StoreKit payment
2. Products load successfully
3. User selects a product
4. User cancels the system purchase dialog

**Expected Embrace Events**:
- Product load span (success)
- Purchase span (user_cancelled status)
- Warning log for cancellation
- Breadcrumb: "StoreKit purchase cancelled"

### Purchase Failure
1. User selects StoreKit payment
2. Products load successfully
3. User selects a product
4. Purchase fails (network error, payment declined, etc.)

**Expected Embrace Events**:
- Product load span (success)
- Purchase span (error status)
- Error log with failure details
- Breadcrumb: "STOREKIT_PAYMENT_ERROR"

### Product Load Failure
1. User selects StoreKit payment
2. Product loading fails (no connection, invalid products, etc.)

**Expected Embrace Events**:
- Product load span (error status)
- Error log with failure reason
- No products available UI state

## Viewing Telemetry in Embrace Dashboard

After running test purchases, log into your Embrace dashboard:

### Performance Traces
1. Navigate to **Performance → Traces**
2. Filter by span names:
   - `storekit_load_products`
   - `storekit_purchase`
   - `storekit_verify_transaction`
3. View duration metrics and success rates

### Logs
1. Navigate to **Logs**
2. Filter by:
   - Severity: info, warn, error
   - Message contains: "StoreKit"
3. Review detailed purchase flow information

### Session Replay
1. Navigate to **Sessions**
2. Select a session with StoreKit activity
3. Review breadcrumb timeline to see user flow
4. Correlate breadcrumbs with logs and spans

## Troubleshooting

### Products Not Loading

**Symptom**: Empty products list or "No products available"

**Solutions**:
1. Verify `Configuration.storekit` is set as default in Xcode
2. Check product IDs match exactly (case-sensitive)
3. Ensure In-App Purchase capability is enabled
4. Review Embrace logs for specific error messages

### Purchase Flow Not Completing

**Symptom**: Purchase appears to start but doesn't complete

**Solutions**:
1. Check Embrace logs for error messages
2. Verify you're signed in with a sandbox account (not production)
3. Ensure products are "Ready to Submit" in App Store Connect
4. Check for network connectivity issues

### Telemetry Not Appearing in Dashboard

**Symptom**: No StoreKit events in Embrace

**Solutions**:
1. Verify Embrace SDK is properly initialized
2. Check that `EmbraceService.shared` is accessible
3. Ensure network requests are completing successfully
4. Wait a few minutes for data to sync to dashboard

### Transaction Verification Failed

**Symptom**: Purchase completes but verification fails

**Solutions**:
1. Check device date/time settings
2. Verify you're using the correct environment (sandbox vs. production)
3. Review verification error in Embrace error logs
4. Ensure StoreKit 2 is available (iOS 15+)

## Product Configuration Best Practices

### Product ID Naming Convention
Use reverse-domain notation:
```
com.yourcompany.appname.producttype.productname
```

Examples:
```
com.embrace.ecommerce.consumable.cart_small
com.embrace.ecommerce.upgrade.premium_shipping
com.embrace.ecommerce.tip.standard
```

### Product Types

- **Consumable**: Items that can be purchased multiple times (cart payments, tips)
- **Non-Consumable**: One-time purchases (premium features)
- **Auto-Renewable Subscription**: Recurring subscriptions
- **Non-Renewing Subscription**: Fixed-duration subscriptions

For e-commerce cart payments, **Consumable** is recommended.

### Pricing Tiers

Match products to typical cart values:
- Tier 1: $0.99 - $4.99 (tips, small items)
- Tier 2: $9.99 - $29.99 (typical orders)
- Tier 3: $49.99 - $99.99 (larger orders)
- Tier 4: $99.99+ (premium/bulk orders)

## Support and Resources

### Apple Documentation
- [StoreKit 2 Overview](https://developer.apple.com/documentation/storekit)
- [In-App Purchase Guide](https://developer.apple.com/in-app-purchase/)
- [Testing In-App Purchases](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases)

### Embrace Documentation
- [Embrace iOS SDK](https://embrace.io/docs/ios/)
- [Performance Monitoring](https://embrace.io/docs/ios/features/performance-monitoring/)
- [Custom Logging](https://embrace.io/docs/ios/features/logging/)

### Sample Code
All StoreKit implementation code is in:
- `Embrace Ecommerce/Services/StoreKitManager.swift` - Core StoreKit logic
- `Embrace Ecommerce/Views/PaymentSelectionView.swift` - UI integration
- `Embrace Ecommerce/Services/CheckoutCoordinator.swift` - Purchase flow
- `Embrace Ecommerce/Models/PaymentMethod.swift` - Data models

## Next Steps

1. **Test Locally**: Run the app with the included Configuration.storekit
2. **View Telemetry**: Complete a test purchase and review data in Embrace
3. **Customize Products**: Replace with your own product IDs and test
4. **Share with Customers**: Provide this app as a reference implementation

The app is ready to demonstrate how StoreKit transactions and events appear in the Embrace dashboard!
