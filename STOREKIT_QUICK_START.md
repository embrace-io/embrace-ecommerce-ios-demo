# StoreKit Integration - Quick Start Guide

## For Embrace Solutions Engineers

This guide helps you quickly demonstrate StoreKit telemetry to customers using this sample app.

## What's Been Added

### 1. Complete StoreKit 2 Implementation
- **StoreKitManager.swift** - Singleton manager handling all StoreKit operations
- **Product loading** with async/await
- **Purchase processing** with transaction verification
- **Transaction monitoring** for real-time updates
- **Restore purchases** functionality

### 2. Comprehensive Embrace Telemetry
Every StoreKit operation is tracked:
- ✅ Performance spans for timing analysis
- ✅ Breadcrumbs for user journey tracking
- ✅ Info/Warning/Error logs for debugging
- ✅ Attributes for detailed context

### 3. UI Integration
- **PaymentSelectionView** - Added "StoreKit Payment" option
- **StoreKitProductRow** - Product selection UI with recommendations
- **CheckoutCoordinator** - Purchase flow integration

### 4. Test Configuration
- **Configuration.storekit** - 6 test products ready to use
- No App Store Connect setup needed for initial testing

## 5-Minute Demo Setup

### 1. Open in Xcode
```bash
cd "Embrace Ecommerce"
open "Embrace Ecommerce.xcodeproj"
```

### 2. Enable In-App Purchase Capability
1. Select project → Target → Signing & Capabilities
2. Click "+ Capability"
3. Add "In-App Purchase"

### 3. Set StoreKit Configuration
1. In Xcode menu: **Editor → Default StoreKit Configuration**
2. Select **Configuration.storekit**

### 4. Run and Test
1. Build and run the app (⌘R)
2. Add items to cart
3. Proceed to checkout
4. Select **"StoreKit Payment"**
5. Choose a product (suggested product highlighted)
6. Complete the test purchase

### 5. View in Embrace Dashboard
1. Log into Embrace dashboard
2. Navigate to your session
3. View:
   - **Performance Traces**: `storekit_purchase`, `storekit_load_products`
   - **Logs**: Filter for "StoreKit"
   - **Breadcrumbs**: See complete purchase flow

## Demo Script

### Introduction (30 seconds)
> "This sample app demonstrates how StoreKit in-app purchases are tracked in Embrace. We've integrated StoreKit 2 with comprehensive telemetry to show you exactly what data you'll see in your dashboard."

### Show the Code (1 minute)
Open `StoreKitManager.swift` and highlight:
- Line 85-115: Product loading with telemetry
- Line 130-200: Purchase flow with comprehensive tracking
- All Embrace span, log, and breadcrumb calls

### Run the Demo (2 minutes)
1. **Launch app**: "The app is already instrumented with Embrace"
2. **Add to cart**: "Adding items to demonstrate cart-based product suggestions"
3. **Checkout**: "Proceeding through the checkout flow..."
4. **StoreKit payment**: "Here's the StoreKit payment option with product selection"
5. **Purchase**: "Notice the recommended product based on cart value"
6. **Complete**: "The system purchase dialog appears, confirming the transaction"

### Show Dashboard (2 minutes)
1. **Open Embrace**: Navigate to the session
2. **Breadcrumbs**: Show the complete StoreKit flow
3. **Traces**: Open `storekit_purchase` span
4. **Attributes**: Point out product ID, transaction ID, price, duration
5. **Logs**: Show info/error logs with context

## Common Customer Questions

### Q: "How do I use my own products?"
**A:** Two options:
1. **Quick Test**: Edit `Configuration.storekit` and change product IDs
2. **Full Integration**: Connect to App Store Connect and update `StoreKitManager.swift` ProductID enum

See `STOREKIT_SETUP.md` for detailed instructions.

### Q: "What if products don't load?"
**A:** Check:
1. Configuration.storekit is set as default
2. In-App Purchase capability is enabled
3. Product IDs match exactly (case-sensitive)
4. Check Embrace error logs for specific failures

### Q: "How do I see failed purchases?"
**A:** Test error scenarios:
1. Cancel the purchase dialog → See "user_cancelled" status
2. Disable network → See loading failure
3. Use invalid product ID → See "product not found" error

All failures are logged in Embrace with detailed error messages.

### Q: "Can I track subscription renewals?"
**A:** Yes! The implementation includes transaction monitoring:
- `listenForTransactions()` tracks all transaction updates
- Auto-renewable subscriptions trigger transaction updates
- Each renewal is logged with telemetry

Change product type in Configuration.storekit to test subscriptions.

### Q: "What's the performance overhead?"
**A:** Minimal:
- Embrace telemetry is asynchronous and non-blocking
- Spans are created at operation start, ended at completion
- No impact on StoreKit purchase flow timing
- All network calls to Embrace happen in background

## Files to Share with Customer

If the customer wants to implement this:

1. **StoreKitManager.swift** - Complete implementation reference
2. **STOREKIT_SETUP.md** - Detailed setup guide
3. **Configuration.storekit** - Example product configuration
4. **PaymentSelectionView.swift** (lines 1-710) - UI integration example

## Customization for Customer Use Cases

### E-commerce Cart Checkout
✅ **Already implemented** - Uses cart value to suggest products

### Subscription Upsell
Update Configuration.storekit:
```json
{
  "type": "Auto-Renewable Subscription",
  "subscriptionGroupID": "group_id"
}
```

### Premium Features
Change to:
```json
{
  "type": "Non-Consumable"
}
```

### Tipping / Donations
Use existing "Tip" product as template:
```json
{
  "type": "Consumable",
  "productID": "com.yourapp.tip_small"
}
```

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| "No products available" | Set Configuration.storekit as default in Xcode |
| Build errors on StoreKit import | Ensure deployment target is iOS 15+ |
| Purchase dialog doesn't appear | Check you're not signed into production App Store |
| Telemetry not in dashboard | Verify Embrace SDK initialized, check network |
| "Product not found" error | Product IDs in code must match Configuration.storekit |

## Next Steps After Demo

1. **Customize products** - Update with customer's actual product IDs
2. **Test with App Store Connect** - Connect to their sandbox environment
3. **Monitor production** - Deploy and track real purchases
4. **Analyze data** - Use Embrace to optimize conversion funnel

## Support Resources

- **Detailed Setup**: STOREKIT_SETUP.md
- **Code Reference**: StoreKitManager.swift
- **Embrace Docs**: https://embrace.io/docs/ios/
- **Apple StoreKit**: https://developer.apple.com/storekit/

---

**Ready to demo!** The app is fully configured for local testing. Just enable the capability and set the configuration file.
