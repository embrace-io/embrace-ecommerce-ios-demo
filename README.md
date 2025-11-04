# Embrace Ecommerce

A test iOS e-commerce app built with SwiftUI, integrating Stripe for payment processing.

## 🚀 Trying Embrace?

If this is your first time using Embrace and you want to try it out in an iOS app, follow these steps:

1. Get the Embrace App ID for your iOS app. This will be available in the [Projects and Apps](https://dash.embrace.io/settings/projects-and-apps) section of the [Embrace dashboard](https://dash.embrace.io).
2. Run the onboarding script:
   ```bash
   bash scripts/onboarding-script.sh
   ```
3. Follow the prompts to configure this demo app with your Embrace credentials

The script will show you demo data in the Embrace dashboard. You can navigate around in the dash to understand how Embrace captures sessions and lets you dig into your app's performance.

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

## 🔍 Embrace SDK - User Flow Tracking

This app implements comprehensive breadcrumb tracking using the Embrace SDK to monitor three distinct checkout user flows.

### Flow 1: Checkout Started → Shipping Completed

Tracks the user journey from checkout initiation through shipping information completion.

| Breadcrumb | Location | Description |
|------------|----------|-------------|
| `CHECKOUT_STARTED` | `CheckoutCoordinator.swift:51` | When checkout is initialized |
| `SHIPPING_INFORMATION_COMPLETED` | `ShippingInformationViewController.swift:204` | When user completes shipping form |
| `CHECKOUT_SHIPPING_COMPLETED` | `CheckoutCoordinator.swift:81` | When transitioning to payment step |

### Flow 2: Shipping Completed → Payment Completed

Tracks the payment processing flow from shipping completion through successful payment.

| Breadcrumb | Location | Description |
|------------|----------|-------------|
| `STRIPE_PAYMENT_PROCESSING_STARTED` | `StripePaymentView.swift:267` | When payment processing begins |
| `STRIPE_PAYMENT_PROCESSING_SUCCESS` | `StripePaymentView.swift:293` | When payment succeeds |
| `STRIPE_PAYMENT_PROCESSING_FAILED` | `StripePaymentView.swift:308` | When payment fails |
| `CHECKOUT_PAYMENT_COMPLETED` | `CheckoutCoordinator.swift:84` | When transitioning to confirmation step |

### Flow 3: Payment Completed → Order Details API Complete

Tracks the final order placement flow from payment completion through successful order creation.

| Breadcrumb | Location | Description |
|------------|----------|-------------|
| `PLACE_ORDER_INITIATED` | `OrderConfirmationViewController.swift:174` | When user taps place order |
| `ORDER_DETAILS_API_COMPLETED` | `CheckoutCoordinator.swift:177` | When order API call completes successfully |
| `ORDER_PLACED_SUCCESS` | `OrderConfirmationViewController.swift:211` | When order placement succeeds |
| `ORDER_PLACED_FAILED` | `OrderConfirmationViewController.swift:230` | When order placement fails |

### Monitoring User Journeys

These breadcrumbs allow you to:
- Track conversion rates through each checkout step
- Identify drop-off points in the checkout flow
- Monitor payment processing success/failure rates
- Analyze the complete user journey from cart to order completion
- Debug issues specific to each flow step

The breadcrumbs are automatically captured in your Embrace sessions and can be viewed in the Embrace dashboard for comprehensive user flow analysis.
