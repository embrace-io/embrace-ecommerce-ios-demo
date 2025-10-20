# Embrace E-Commerce App - Setup Instructions

A fully-functional iOS e-commerce demo app designed to showcase Embrace SDK telemetry capabilities. Get it running in **5 minutes** with just your Embrace App ID!

## Quick Start (5 Minutes)

**Just want to see Embrace in action? Follow these steps:**

1. **Get Your Embrace App ID**
   - Sign up at [dash.embrace.io](https://dash.embrace.io)
   - Click "Create New App" → Select "iOS" platform
   - Copy your App ID (format: `xxxxx`)

2. **Configure the App**
   - Open `Embrace Ecommerce/Services/SDKConfiguration.swift`
   - Replace line 16:
     ```swift
     static let appId = "your_app_id_here"  // Paste your App ID
     ```

3. **Build & Run**
   ```bash
   open "Embrace Ecommerce.xcodeproj"
   # Or use Xcode: ⌘+R to build and run
   ```

4. **View Telemetry in Embrace Dashboard**
   - Browse products, add to cart, complete checkout
   - Go to [dash.embrace.io](https://dash.embrace.io)
   - View your session with breadcrumbs, logs, and traces

**That's it!** All payment providers work in test mode without additional setup. See [Optional Configuration](#optional-configuration) below for advanced features.

---

## Prerequisites

- Xcode 15.0 or later
- iOS 18.2+ deployment target
- macOS with Xcode Command Line Tools installed

### Required Accounts

- ✅ **[Embrace](https://embrace.io)** - Required for telemetry

### Optional Accounts (For Advanced Features)

- **[Mixpanel](https://mixpanel.com)** - Analytics comparison (app works without it)
- **[Stripe](https://stripe.com)** - Custom payment testing (uses test mode by default)
- **[Google Cloud Console](https://console.cloud.google.com)** - Google Sign-In (falls back to email auth)

## What You'll See in Embrace

Once configured, this app captures comprehensive telemetry:

### User Flows Tracked
- **User Authentication** - Email & Google Sign-In flows
- **Checkout Journey** - Start → Shipping → Payment → Confirmation
- **Payment Processing** - Stripe & StoreKit purchase flows
- **Order Placement** - API calls and completion tracking

### Telemetry Captured
- **Breadcrumbs** - 20+ user action breadcrumbs across 4 flows
- **Performance Traces** - Network calls, StoreKit operations
- **Error Logs** - Payment failures, network errors, validation issues
- **Session Properties** - App type, environment, test mode flags
- **Network Monitoring** - Simulated API calls with realistic delays
- **View Tracking** - Automatic screen view capture

See the [README.md](./README.md) for complete breadcrumb locations and flow diagrams.

---

## Configuration Details

### 1. Embrace SDK (Required)

The Embrace SDK is the core monitoring solution for this app.

**Detailed Steps:**

1. **Create an Embrace Account**
   - Go to [dash.embrace.io](https://dash.embrace.io)
   - Sign up for a free account

2. **Create Your iOS App**
   - In the dashboard, click **"Create New App"**
   - Select **"iOS"** as the platform
   - Name it (e.g., "Ecommerce Demo")
   - Copy your **App ID** (5-character code like `c6jp3`)

3. **Update Configuration File**
   - Open `Embrace Ecommerce/Services/SDKConfiguration.swift`
   - Find line 16 and replace with your App ID:
   ```swift
   struct Embrace {
       static let appId = "c6jp3"  // Replace with YOUR App ID
       // ... rest stays the same
   }
   ```

4. **Verify Setup**
   - Build and run the app
   - Check Xcode console for: `✅ Embrace SDK initialized`
   - Complete a checkout flow
   - View the session in your Embrace dashboard within 1-2 minutes

**Troubleshooting:**
- If you see "Embrace SDK not configured", double-check your App ID
- Sessions appear in the dashboard with 1-2 minute delay
- Ensure you're on the same org/app in the dashboard

---

## Optional Configuration

**The app works perfectly with just your Embrace App ID.** Configure these only if you want to test specific integrations or use your own accounts.

### 2. Google Services (Optional - for Google Sign-In)

**Without this:** App uses email-based authentication (fully functional)

**Steps:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select existing one
3. Enable Google Sign-In API
4. Create OAuth 2.0 credentials:
   - Application type: iOS
   - Bundle ID: `com.embrace.org.Embrace-Ecommerce`
5. Download the `GoogleService-Info.plist`
6. Copy it to: `Embrace Ecommerce/GoogleService-Info.plist`

**Template Available:**
- See `GoogleService-Info.plist.example` for the required structure
- Replace `YOUR_GOOGLE_CLIENT_ID` with your actual client ID

### 3. Mixpanel Analytics (Optional)

**Without this:** App works fine; Mixpanel SDK uses mock implementation

**Why configure:** Compare Embrace telemetry with another analytics tool

**Steps:**
1. Sign up at https://mixpanel.com
2. Create a new project
3. Copy your Project Token from Settings → Project Settings
4. Open `Embrace Ecommerce/Services/SDKConfiguration.swift`
5. Update line 46:

```swift
struct Mixpanel {
    static let projectToken = "abc123..."  // Replace with your token
    // ...
}
```

**Default Behavior:**
- Token placeholder: `"YOUR_MIXPANEL_PROJECT_TOKEN"`
- App automatically detects and uses mock implementation

### 4. Stripe Payment Processing (Optional)

**Without this:** Stripe SDK works in test mode with placeholder key

**Why configure:** Test with your own Stripe account or webhook events

**Steps:**
1. Sign up at https://stripe.com
2. Get your test publishable key from https://dashboard.stripe.com/test/apikeys
3. Open `Embrace Ecommerce/Services/SDKConfiguration.swift`
4. Update line 59:

```swift
struct Stripe {
    static let publishableKey = "pk_test_ABC..."  // Your test key
    // ...
}
```

**Test Card Numbers:**
- Success: `4242 4242 4242 4242`
- Declined: `4000 0000 0000 0002`
- See [README.md](./README.md) for more test cards

**Important:**
- Only use test keys (prefix: `pk_test_`)
- Never commit live keys to version control

### 5. StoreKit Configuration (Optional)

**Without this:** StoreKit works with included test configuration

**Why configure:** Test with real App Store Connect products

**For Local Testing (Default - Works Out of Box):**
1. The app includes `Configuration.storekit` with test products
2. In Xcode: `Editor → Default StoreKit Configuration → Configuration.storekit`
3. Products already configured:
   - Single Item ($9.99)
   - Small Cart ($29.99)
   - Medium Cart ($49.99)
   - Large Cart ($99.99)
   - Premium Shipping ($4.99)
   - Tip ($0.99)

**For App Store Connect Products:**
1. Create products in App Store Connect
2. Update `Embrace Ecommerce/Services/StoreKitManager.swift` with your product IDs
3. See [STOREKIT_SETUP.md](./STOREKIT_SETUP.md) for detailed instructions

**StoreKit Telemetry:**
- Product loading performance
- Purchase flow tracking
- Transaction verification events
- Cancellation and error tracking

---

## Verification & Testing

After configuring your Embrace App ID, verify everything works:

### 1. Build & Launch

**Using Xcode:**
```bash
open "Embrace Ecommerce.xcodeproj"
# Press ⌘+R to build and run
```

**Using Command Line:**
```bash
xcodebuild -scheme "Embrace Ecommerce" build
```

### 2. Check Console Output

Look for these messages when the app launches:

```
🔧 SDK Configuration Status:
=============================
✅ Embrace SDK initialized successfully
⚠️ Mixpanel project token not configured - using mock
⚠️ Stripe publishable key not configured - using placeholder

SDK Versions:
- Embrace SDK: 6.13.0
- Firebase SDK: 12.1.0
- Stripe SDK: 24.19.0
```

**Expected warnings** (if you did Quick Start only):
- Mixpanel warning - normal, app works fine
- Stripe warning - normal, test mode still works
- Google Sign-In fallback - normal, use email auth

### 3. Test a Complete User Flow

**Step-by-step test:**

1. **Login**
   - Use email: `test@example.com`
   - Use any password (mock auth)
   - Check for `USER_LOGIN_SUCCESS_EMAIL` breadcrumb

2. **Browse & Add to Cart**
   - Tap any product
   - Add 2-3 items to cart
   - Navigate back to home

3. **Checkout Flow**
   - Tap cart → "Proceed to Checkout"
   - Fill shipping info (any data works)
   - Check for `CHECKOUT_STARTED` breadcrumb

4. **Complete Payment**
   - Choose "Stripe Payment"
   - Card: `4242 4242 4242 4242`
   - Exp: `12/28`, CVC: `123`
   - Check for `STRIPE_PAYMENT_PROCESSING_SUCCESS`

5. **Place Order**
   - Tap "Place Order"
   - Wait for success message
   - Check for `ORDER_PLACED_SUCCESS` breadcrumb

### 4. View Telemetry in Embrace Dashboard

**Check your dashboard:**

1. Go to [dash.embrace.io](https://dash.embrace.io)
2. Select your app
3. Navigate to **Sessions** tab
4. Find your recent session (1-2 minute delay)
5. Verify you see:
   - Session duration
   - Breadcrumbs timeline (checkout flow)
   - Network traces (API calls)
   - View captures (screen transitions)
   - Session properties (app_type, environment)

**Expected breadcrumbs:**
- `USER_LOGIN_SUCCESS_EMAIL`
- `CHECKOUT_STARTED`
- `SHIPPING_INFORMATION_COMPLETED`
- `STRIPE_PAYMENT_PROCESSING_STARTED`
- `STRIPE_PAYMENT_PROCESSING_SUCCESS`
- `PLACE_ORDER_INITIATED`
- `ORDER_DETAILS_API_COMPLETED`
- `ORDER_PLACED_SUCCESS`

## Troubleshooting

### Embrace Issues

**"Embrace SDK not configured" or "Invalid App ID"**
- Double-check your App ID in `SDKConfiguration.swift` line 16
- Ensure no extra spaces or quotes
- Verify app exists in [dash.embrace.io](https://dash.embrace.io)
- Check network connection (SDK requires internet for first launch)
- Deployment target must be iOS 18.2+

**"Sessions not appearing in dashboard"**
- Sessions have 1-2 minute upload delay (normal)
- Ensure you're logged into the correct Embrace org
- Verify App ID matches the dashboard app
- Check console for "Session uploaded successfully"
- Try backgrounding the app (triggers upload)

**"No breadcrumbs in session"**
- Complete a full checkout flow (just launching isn't enough)
- Check console for breadcrumb logs like `[Embrace] Added breadcrumb: CHECKOUT_STARTED`
- Verify Embrace SDK initialized before user actions

### Optional Service Issues

**"Mixpanel using placeholder token"**
- This is expected and normal
- App works perfectly without Mixpanel
- Only configure if you want to compare analytics platforms

**"Stripe payment failed" or "Invalid publishable key"**
- Default placeholder key works for basic testing
- For custom testing: Update `SDKConfiguration.swift` line 59
- Ensure key starts with `pk_test_` (never use live keys)
- Test cards: See [README.md](./README.md)

**"Google Sign-In failed"**
- Expected without `GoogleService-Info.plist`
- Use email authentication instead (fully functional)
- To fix: Follow [Google Services setup](#2-google-services-optional---for-google-sign-in)

**StoreKit Products Not Loading**
- In Xcode: `Editor → Default StoreKit Configuration → Configuration.storekit`
- Check product IDs match in `StoreKitManager.swift`
- Enable In-App Purchase capability in project settings
- Clean build folder: `⌘+Shift+K` then rebuild

### Build Issues

**"Command PhaseScriptExecution failed"**
- Clean build folder: `Product → Clean Build Folder` (⌘+Shift+K)
- Delete derived data: `~/Library/Developer/Xcode/DerivedData`
- Restart Xcode

**"Module 'X' not found"**
- File → Packages → Reset Package Caches
- File → Packages → Resolve Package Versions
- Check Swift Package dependencies are downloaded

**"Signing issues"**
- Select your development team in project settings
- Or use automatic signing with your Apple ID

---

## Security Best Practices

This is a demo app, but it's important to follow security best practices:

### DO:
- **Use test credentials only** - All API keys should be test/development keys
- **Keep `.gitignore` updated** - Sensitive files are already listed
- **Use environment variables** - For production apps, never hardcode secrets
- **Review before commits** - Check you're not committing API keys
- **Rotate keys regularly** - Especially if accidentally exposed

### DON'T:
- **Never commit production keys** - This is a public demo
- **Don't share your Embrace App ID publicly** - It's linked to your account
- **Don't use live Stripe keys** - Only `pk_test_` keys in demo apps
- **Don't commit `GoogleService-Info.plist`** - Already in `.gitignore`

### Files Automatically Ignored:
```
GoogleService-Info.plist
.env files
credentials.json / secrets.json
*.mobileprovision, *.p12 (certificates)
```

---

## Project Structure

Key configuration files:

```
Embrace Ecommerce/
├── Services/
│   ├── SDKConfiguration.swift           # Main config (API keys here)
│   ├── StripePaymentService.swift       # Stripe integration
│   ├── StoreKitManager.swift            # In-app purchases
│   └── CheckoutCoordinator.swift        # Breadcrumb tracking
├── GoogleService-Info.plist             # Git-ignored (optional)
├── GoogleService-Info.plist.example     # Template
└── Configuration.storekit               # StoreKit test products
```

---

## Additional Resources

### Documentation
- **[README.md](./README.md)** - App overview & breadcrumb reference
- **[STOREKIT_SETUP.md](./STOREKIT_SETUP.md)** - Detailed StoreKit guide
- **[STOREKIT_QUICK_START.md](./STOREKIT_QUICK_START.md)** - Quick StoreKit reference

### Embrace Resources
- **[Embrace Documentation](https://embrace.io/docs)** - Official SDK docs
- **[Embrace Dashboard](https://dash.embrace.io)** - View your telemetry
- **[Embrace iOS Guide](https://embrace.io/docs/ios)** - Integration guides
- **[Embrace Support](https://embrace.io/support)** - Get help

### Third-Party SDKs
- **[Stripe iOS SDK](https://docs.stripe.com/payments/accept-a-payment?platform=ios)** - Payment integration
- **[StoreKit 2 Guide](https://developer.apple.com/storekit/)** - In-app purchases
- **[Google Sign-In](https://developers.google.com/identity/sign-in/ios)** - OAuth integration

---

## Next Steps

### For Quick Testing:
1. Configure Embrace App ID (5 minutes)
2. Build and run the app
3. Complete a checkout flow
4. View session in Embrace dashboard

### For Full Demo:
1. Configure all optional services
2. Test different payment flows (Stripe + StoreKit)
3. Test authentication methods (Email + Google)
4. Explore error scenarios (failed payments, network issues)
5. Compare Embrace vs Mixpanel telemetry

### For Production Use:
**WARNING: This is a demo app** - For production apps, implement:
- Proper secret management (Xcode Build Configurations, environment vars)
- Secure credential storage (iOS Keychain)
- Backend API integration (not mocked)
- Real payment processing
- App Store Connect configuration

---

## Getting Help

### Issues with This Demo App:
- Create an issue on the GitHub repository
- Check the troubleshooting section above
- Review console logs for error messages

### Embrace SDK Questions:
- **Docs:** [embrace.io/docs](https://embrace.io/docs)
- **Support:** [embrace.io/support](https://embrace.io/support)
- **Community:** Embrace Slack channel

### Payment Provider Questions:
- **Stripe:** [support.stripe.com](https://support.stripe.com)
- **StoreKit:** [Apple Developer Forums](https://developer.apple.com/forums/)

---

**Happy testing!** Questions or feedback? Reach out to the Embrace team or open an issue.
