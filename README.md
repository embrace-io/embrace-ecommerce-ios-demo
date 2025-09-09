# Embrace Ecommerce

A test iOS e-commerce app built with SwiftUI, integrating Stripe for payment processing.

## 💳 Stripe Testing Information

This app is configured for **test mode only** - no real payments will be processed.

### Test Credit Card Numbers

Use these test card numbers for payment testing:

| Card Type | Number | Description |
|-----------|--------|-------------|
| **Visa (Success)** | `4242424242424242` | Payment succeeds |
| **Visa (Declined)** | `4000000000000002` | Payment declined |
| **Mastercard (Success)** | `5555555555554444` | Payment succeeds |
| **American Express (Success)** | `378282246310005` | Payment succeeds |
| **Charge Customer Fail** | `4000000000000341` | Charge fails after payment method setup |
| **Authentication Required** | `4000002500003155` | Requires 3D Secure authentication |

### Test Card Details

For any of the above test cards, use:
- **Expiry Date**: Any future date (e.g., `12/28`)
- **CVC**: Any 3-digit number (e.g., `123`)
- **ZIP Code**: Any valid ZIP code (e.g., `12345`)

### Testing Different Scenarios

1. **Successful Payment**: Use `4242424242424242`
2. **Declined Payment**: Use `4000000000000002`
3. **Test Payment Failure Button**: Use the red "Test Payment Failure" button in the app

### Important Notes

⚠️ **This is a test environment** - All payments are simulated and no real money is processed.

✅ **URL Scheme Configured**: The app handles Stripe redirects via `embrace-ecommerce://stripe-redirect`

📱 **SDK Version**: Using Stripe iOS SDK 24.19.0+ with the latest PaymentSheet implementation