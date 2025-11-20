# Startup Instrumentation API Comparison: Android vs iOS

This document compares the Android and iOS Embrace SDK APIs for customizing startup instrumentation.

## Overview

Both Android and iOS SDKs provide similar capabilities for adding custom child spans to the startup trace, but with platform-specific implementations.

---

## API Comparison Table

| Feature | Android | iOS |
|---------|---------|-----|
| **Add Custom Child Span** | `addStartupTraceAttribute()` | `recordCompletedChildSpan()` or `buildChildSpan()` |
| **Add Attributes to Root Trace** | Via span attributes | `addAttributesToTrace()` |
| **Get SDK Time** | `getSdkCurrentTimeMs()` | Use standard `Date()` |
| **Span Events** | Supported via parameter | Via `span.addEvent()` on built spans |
| **Error Code** | Supported via parameter | Via `span.status` on built spans |

---

## 1. Adding Custom Child Spans

### Android
```java
// Android: Single method with all parameters
Embrace.getInstance().addStartupTraceAttribute(
    name: "custom-initialization",
    startTime: startTimeMs,
    endTime: endTimeMs,
    attributes: mapOf(
        "component" to "database",
        "operation" to "migration"
    ),
    spanEvents: listOf(
        SpanEvent("validation_complete", timestamp)
    ),
    errorCode: ErrorCode.NONE
);
```

### iOS - Option 1: Record Completed Span
```swift
// iOS: Simple completed span recording
let success = Embrace.client?.startupInstrumentation.recordCompletedChildSpan(
    name: "custom-initialization",
    type: .startup,
    startTime: startTime,
    endTime: endTime,
    attributes: [
        "component": "database",
        "operation": "migration"
    ]
)
```

### iOS - Option 2: Build and Control Span Manually
```swift
// iOS: Manual control for events and error codes
if let span = Embrace.client?.startupInstrumentation.buildChildSpan(
    name: "custom-initialization",
    type: .startup,
    startTime: Date(),
    attributes: [
        "component": "database",
        "operation": "migration"
    ]
)?.startSpan() {

    // Add events during execution
    span.addEvent(name: "validation_complete")

    // Set error code/status
    span.status = .error(description: "Migration failed")

    // End the span
    span.end()
}
```

---

## 2. Adding Attributes to Root Trace

### Android
```java
// Android: Attributes are typically added via the span directly
Embrace.getInstance().addStartupTraceAttribute(
    name: "root-metadata",
    startTime: startTime,
    endTime: endTime,
    attributes: mapOf("key" to "value")
);
```

### iOS
```swift
// iOS: Dedicated method for root trace attributes
Embrace.client?.startupInstrumentation.addAttributesToTrace([
    "custom_key": "custom_value",
    "app_mode": "production",
    "feature_flags": "enabled"
])
```

---

## 3. Time Synchronization

### Android
```java
// Android: Use SDK's synchronized clock
long startTime = Embrace.getInstance().getSdkCurrentTimeMs();
// ... perform operation ...
long endTime = Embrace.getInstance().getSdkCurrentTimeMs();

Embrace.getInstance().addStartupTraceAttribute(
    name: "operation",
    startTime: startTime,
    endTime: endTime
);
```

### iOS
```swift
// iOS: Use standard Swift Date - SDK handles synchronization internally
let startTime = Date()
// ... perform operation ...
let endTime = Date()

Embrace.client?.startupInstrumentation.recordCompletedChildSpan(
    name: "operation",
    startTime: startTime,
    endTime: endTime
)

// Note: The SDK internally uses EmbraceClock for consistent time tracking
// See: Sources/EmbraceCommonInternal/Clock/EmbraceClock.swift
```

---

## 4. Comprehensive Example

### Android
```java
public void customStartupInstrumentation() {
    // Get SDK time
    long startTime = Embrace.getInstance().getSdkCurrentTimeMs();

    // Perform initialization
    initializeDatabase();
    long dbEndTime = Embrace.getInstance().getSdkCurrentTimeMs();

    // Add database span with events
    Embrace.getInstance().addStartupTraceAttribute(
        "database-init",
        startTime,
        dbEndTime,
        mapOf(
            "db_type" to "sqlite",
            "version" to "3"
        ),
        listOf(
            new SpanEvent("migration_complete", dbEndTime)
        ),
        ErrorCode.NONE
    );
}
```

### iOS
```swift
func customStartupInstrumentation() {
    // Capture start time
    let startTime = Date()

    // Perform initialization
    initializeDatabase()
    let dbEndTime = Date()

    // Option 1: Simple span recording
    Embrace.client?.startupInstrumentation.recordCompletedChildSpan(
        name: "database-init",
        type: .startup,
        startTime: startTime,
        endTime: dbEndTime,
        attributes: [
            "db_type": "sqlite",
            "version": "3"
        ]
    )

    // Option 2: With events
    if let span = Embrace.client?.startupInstrumentation.buildChildSpan(
        name: "database-init",
        type: .startup,
        startTime: startTime,
        attributes: [
            "db_type": "sqlite",
            "version": "3"
        ]
    )?.startSpan() {

        span.addEvent(name: "migration_complete")
        span.end(time: dbEndTime)
    }
}
```

---

## Key Differences

### 1. **Method Design Philosophy**
- **Android**: Single method with all parameters (all-in-one approach)
- **iOS**: Two methods for different use cases:
  - `recordCompletedChildSpan()` - Simple, completed spans
  - `buildChildSpan()` - Advanced control with events/status

### 2. **Time Handling**
- **Android**: Explicit SDK time method (`getSdkCurrentTimeMs()`)
- **iOS**: Standard platform types (`Date`), SDK handles sync internally

### 3. **Span Events & Error Codes**
- **Android**: Parameters in the main method
- **iOS**: Added via the `Span` object when using `buildChildSpan()`

### 4. **Type Safety**
- **Android**: String-based types
- **iOS**: Enum-based `SpanType` (e.g., `.startup`, `.viewLoad`)

---

## Implementation Guide

### When to use `recordCompletedChildSpan()` (iOS)
✅ You have already measured start and end times
✅ You don't need to add span events
✅ You don't need to set error codes/status
✅ Simple, straightforward tracking

### When to use `buildChildSpan()` (iOS)
✅ You need to add span events during execution
✅ You need to set error codes or status
✅ You want to add attributes dynamically
✅ You need fine-grained control over the span lifecycle

---

## References

### iOS SDK
- **API Implementation**: `Sources/EmbraceCore/Public/Startup/StartupInstrumentation+Customization.swift`
- **Documentation**: `docs/ios/6x/advanced-features/startup-instrumentation.md`
- **Time Handling**: `Sources/EmbraceCommonInternal/Clock/EmbraceClock.swift`

### Android SDK
- **Documentation**: `https://embrace.io/docs/android/features/performance-instrumentation/`

---

## Example Code Location

See `/Embrace Ecommerce/Examples/StartupInstrumentationExample.swift` for complete working examples.

See `/Embrace Ecommerce/Embrace_EcommerceApp.swift` (lines 128-173) for real implementation in the app.
