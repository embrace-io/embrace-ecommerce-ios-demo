# Embrace Ecommerce

A comprehensive iOS e-commerce sample app built with SwiftUI, integrating multiple payment providers (Stripe and StoreKit) to demonstrate Embrace SDK telemetry capabilities.

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

## 🛒 StoreKit In-App Purchase Integration

This app includes a comprehensive **StoreKit 2** implementation demonstrating how in-app purchase telemetry appears in Embrace dashboards.

### Features

✅ **Full StoreKit 2 Implementation** - Modern async/await based API
✅ **Comprehensive Telemetry** - Spans, logs, and breadcrumbs for all StoreKit events
✅ **Local Testing** - Includes Configuration.storekit for testing without App Store Connect
✅ **Product Recommendations** - Smart product suggestions based on cart value
✅ **Transaction Verification** - Cryptographic signature validation with telemetry
✅ **Error Tracking** - Detailed error logging for debugging

### Quick Start

1. **Enable In-App Purchase capability** in Xcode
2. **Set Configuration.storekit** as the default StoreKit configuration
3. **Run the app** and select "StoreKit Payment" at checkout
4. **Choose a product** and complete the test purchase
5. **View telemetry** in your Embrace dashboard

### Test Products Available

| Product | Price | Description |
|---------|-------|-------------|
| Single Item | $9.99 | For small purchases |
| Small Cart | $29.99 | For 2-3 items |
| Medium Cart | $49.99 | For 4-6 items |
| Large Cart | $99.99 | For 7+ items |
| Premium Shipping | $4.99 | Shipping upgrade |
| Tip | $0.99 | Gratuity |

### Telemetry Captured

The StoreKit integration captures:
- **Product Loading** - Performance and success/failure metrics
- **Purchase Flow** - Complete transaction lifecycle tracking
- **Transaction Verification** - Signature validation events
- **Transaction Updates** - Real-time transaction state changes
- **Restore Purchases** - Purchase restoration operations
- **Errors & Cancellations** - Detailed failure tracking

### Documentation

See **[STOREKIT_SETUP.md](./STOREKIT_SETUP.md)** for:
- Complete setup instructions
- How to use your own products from App Store Connect
- Viewing telemetry in Embrace dashboard
- Troubleshooting guide
- Best practices for product configuration

## 🔍 Embrace SDK - User Flow Tracking

This app implements comprehensive breadcrumb tracking using the Embrace SDK to monitor four distinct user flows.

### Flow 0: User Login Flow

Tracks the user authentication journey from login initiation through completion (success or failure).

| Breadcrumb | Location | Description |
|------------|----------|-------------|
| `USER_LOGIN_STARTED_EMAIL` | `AuthenticationManager.swift:57` | When email login is initiated |
| `USER_LOGIN_STARTED_GOOGLE` | `AuthenticationManager.swift:211` | When Google Sign-In is initiated |
| `USER_LOGIN_SUCCESS_EMAIL` | `AuthenticationManager.swift:89` | When email login succeeds |
| `USER_LOGIN_SUCCESS_GOOGLE` | `AuthenticationManager.swift:246` | When Google Sign-In succeeds |
| `USER_LOGIN_FAILED_EMAIL` | `AuthenticationManager.swift:97` | When email login fails |
| `USER_LOGIN_FAILED_GOOGLE` | `AuthenticationManager.swift:255` | When Google Sign-In fails |

## 🔍 Checkout User Flows

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

### Flow 4: StoreKit Purchase Flow

Tracks the complete StoreKit in-app purchase journey from initiation through completion.

| Breadcrumb | Location | Description |
|------------|----------|-------------|
| `StoreKit manager initialized` | `StoreKitManager.swift:73` | When StoreKit manager is initialized |
| `Loading StoreKit products` | `StoreKitManager.swift:86` | When product fetch begins |
| `Loaded X StoreKit products` | `StoreKitManager.swift:111` | When products are successfully loaded |
| `StoreKit purchase initiated: [Product]` | `StoreKitManager.swift:138` | When user initiates purchase |
| `StoreKit purchase completed: [Product]` | `StoreKitManager.swift:165` | When purchase succeeds |
| `StoreKit purchase cancelled: [Product]` | `StoreKitManager.swift:182` | When user cancels purchase |
| `STOREKIT_PAYMENT_INITIATED` | `CheckoutCoordinator.swift:232` | When payment processing starts |
| `STOREKIT_PAYMENT_SUCCESS` | `CheckoutCoordinator.swift:247` | When payment completes successfully |
| `STOREKIT_PAYMENT_CANCELLED` | `CheckoutCoordinator.swift:254` | When payment is cancelled |
| `STOREKIT_PAYMENT_ERROR` | `CheckoutCoordinator.swift:263` | When payment fails with error |

### Monitoring User Journeys

These breadcrumbs allow you to:
- Track conversion rates through each checkout step
- Identify drop-off points in the checkout flow
- Monitor payment processing success/failure rates (Stripe & StoreKit)
- Analyze the complete user journey from cart to order completion
- Compare performance between different payment methods
- Track StoreKit product loading performance and purchase completion
- Monitor in-app purchase conversion funnels
- Debug issues specific to each flow step

The breadcrumbs are automatically captured in your Embrace sessions and can be viewed in the Embrace dashboard for comprehensive user flow analysis.