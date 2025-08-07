# Embrace SDK Setup Documentation

## Current Status ✅

The Embrace iOS SDK (v6.13.0) has been integrated into the dogfooding e-commerce app with comprehensive telemetry capabilities.

## What's Configured

### ✅ Core Embrace SDK Setup
- **SDK Version**: 6.13.0 
- **Configuration**: Comprehensive telemetry options enabled
- **Network Monitoring**: Enabled with trace header injection
- **Automatic View Capture**: Enabled for UIKit and SwiftUI
- **Session Properties**: Configured for dogfooding identification

### ✅ Third-Party SDK Integration
- **Firebase SDK** (v12.1.0): Analytics, Crashlytics, Performance
- **Mixpanel SDK**: Analytics with automatic event tracking
- **Stripe SDK** (v24.19.0): Payment processing
- **Google Sign-In SDK** (v9.0.0): Authentication

### ✅ Telemetry Service Wrapper
- Centralized `EmbraceService` class for all telemetry needs
- E-commerce specific tracking methods (products, cart, checkout, etc.)
- Authentication flow tracking
- Search and user action tracking
- Network request monitoring
- Error and exception handling

### ✅ SDK Compatibility Testing
- Automated compatibility tests on app startup (Debug mode)
- Tests concurrent operations between SDKs
- Validates network monitoring compatibility
- Tests session property management

## File Structure

```
Services/
├── EmbraceService.swift          # Main telemetry service wrapper
├── SDKConfiguration.swift        # Centralized configuration
└── SDKCompatibilityTest.swift    # Compatibility testing suite

Embrace_EcommerceApp.swift        # SDK initialization
```

## Configuration Required

### 🔄 Pending Configuration (Replace Placeholders)

1. **Embrace App ID**
   - Location: `SDKConfiguration.swift` → `Embrace.appId`
   - Get from: Embrace Dashboard → App Settings
   
2. **Mixpanel Project Token** (optional)
   - Location: `SDKConfiguration.swift` → `Mixpanel.projectToken`
   - Get from: Mixpanel Dashboard → Project Settings

3. **Firebase Configuration** (optional)
   - Add `GoogleService-Info.plist` to project
   - Get from: Firebase Console → Project Settings

## Features Implemented

### Required Telemetry Coverage ✅
- [x] **Sessions**: Foreground/background with custom properties
- [x] **Tracing**: Custom spans with child spans and events
- [x] **Logs**: Error, Warning, Info, Debug levels
- [x] **Auto-instrumentation**: Startup, view rendering, network calls, tap capture
- [x] **Error Handling**: Crash reporting, handled exceptions, error events
- [x] **Breadcrumbs**: User action tracking throughout the app

### E-commerce Specific Tracking ✅
- [x] Product view tracking
- [x] Add to cart events
- [x] Purchase flow monitoring
- [x] Authentication events
- [x] Search functionality tracking
- [x] User journey breadcrumbs

### Advanced Features ✅
- [x] Network request monitoring with trace headers
- [x] Deep link / URL scheme tracking
- [x] Session property management
- [x] Third-party SDK compatibility
- [x] Debug configuration validation

## Usage Examples

### Basic Logging
```swift
EmbraceService.shared.logInfo("User logged in", properties: ["method": "email"])
EmbraceService.shared.logError("Payment failed", properties: ["reason": "invalid_card"])
```

### Custom Spans
```swift
let span = EmbraceService.shared.startSpan(name: "checkout_process", type: .performance)
span?.addAttribute(key: "total_amount", value: "99.99")
// ... perform checkout logic
span?.end()
```

### E-commerce Tracking
```swift
EmbraceService.shared.trackProductView(productId: "123", productName: "T-Shirt", category: "Clothing", price: 29.99)
EmbraceService.shared.trackPurchaseSuccess(orderId: "ORD-123", totalAmount: 99.99, paymentMethod: "credit_card")
```

## Testing & Validation

The SDK setup includes automated compatibility tests that run on app startup in Debug mode:

1. **Firebase Compatibility**: Tests concurrent operation with Firebase SDKs
2. **Mixpanel Compatibility**: Validates analytics tracking alongside Embrace
3. **Network Monitoring**: Tests concurrent network request capture
4. **Logging Performance**: Validates rapid logging capabilities

## Next Steps

1. **Update App ID**: Replace placeholder with actual Embrace App ID
2. **Configure Partners**: Add actual API keys for Mixpanel, Firebase (optional)
3. **Test Integration**: Run app and verify telemetry in Embrace Dashboard
4. **Add Custom Events**: Implement app-specific telemetry as features are added

## Troubleshooting

- Check console output for configuration warnings
- Verify SDK compatibility tests pass on startup
- Monitor Embrace Dashboard for incoming telemetry
- Review `SDKConfiguration.validateConfiguration()` output

## Documentation Links

- [Embrace iOS SDK Documentation](https://embrace.io/docs/ios/)
- [Embrace Dashboard](https://dash.embrace.io/)
- [SDK Configuration Reference](https://embrace.io/docs/ios/features/configuration/)