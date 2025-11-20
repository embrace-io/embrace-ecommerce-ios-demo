//
//  StartupInstrumentationExample.swift
//  Embrace Ecommerce
//
//  Example demonstrating correct usage of Embrace Startup Instrumentation APIs
//  This file serves as a reference for implementing custom startup spans
//

import Foundation
import EmbraceIO

/// Example class demonstrating various startup instrumentation patterns
class StartupInstrumentationExample {

    /// Example 1: Adding attributes to the startup trace
    /// This adds metadata to the root startup span
    static func addAttributesExample() {
        Embrace.client?.startupInstrumentation.addAttributesToTrace([
            "custom_key": "custom_value",
            "app_mode": "production",
            "feature_flags": "enabled"
        ])
    }
    

    /// Example 2: Recording a completed child span
    /// Use this when you have already measured start and end times
    static func recordCompletedSpanExample() {
        let startTime = Date()

        // Simulate some initialization work
        Thread.sleep(forTimeInterval: 0.1)

        let endTime = Date()

        // Record the completed span
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

        print("Span recorded: \(success ?? false)")
    }

    /// Example 3: Building and manually controlling a span
    /// Use this when you need more control over the span lifecycle
    static func buildAndControlSpanExample() {
        // Build the span
        guard let span = Embrace.client?.startupInstrumentation.buildChildSpan(
            name: "network-configuration",
            type: .startup,
            startTime: Date(),
            attributes: [
                "endpoint": "https://api.example.com",
                "timeout": "30s"
            ]
        )?.startSpan() else {
            print("Failed to create span")
            return
        }

        // Perform work
        Thread.sleep(forTimeInterval: 0.05)

        // Add events during the span's lifecycle
        span.addEvent(name: "configuration_loaded")

        // Add more attributes dynamically
        span.setAttribute(key: "status", value: "success")

        // More work
        Thread.sleep(forTimeInterval: 0.05)

        // Add another event
        span.addEvent(name: "validation_complete")

        // End the span
        span.end()

        print("Manual span completed")
    }

    /// Example 4: Comprehensive startup tracking
    /// This shows how to track multiple initialization steps
    static func comprehensiveExample() {
        let overallStartTime = Date()

        // Track database initialization
        let dbStartTime = Date()
        // ... database work ...
        Thread.sleep(forTimeInterval: 0.02)
        Embrace.client?.startupInstrumentation.recordCompletedChildSpan(
            name: "database-initialization",
            type: .startup,
            startTime: dbStartTime,
            endTime: Date(),
            attributes: ["db_type": "sqlite", "migration_version": "3"]
        )

        // Track network configuration with manual span
        if let networkSpan = Embrace.client?.startupInstrumentation.buildChildSpan(
            name: "network-setup",
            type: .startup,
            startTime: Date(),
            attributes: ["api_version": "v2"]
        )?.startSpan() {

            // Configure API endpoints
            Thread.sleep(forTimeInterval: 0.01)
            networkSpan.addEvent(name: "endpoints_configured")

            // Setup auth tokens
            Thread.sleep(forTimeInterval: 0.01)
            networkSpan.addEvent(name: "auth_initialized")

            networkSpan.end()
        }

        // Track cache warm-up
        let cacheStartTime = Date()
        Thread.sleep(forTimeInterval: 0.015)
        Embrace.client?.startupInstrumentation.recordCompletedChildSpan(
            name: "cache-warmup",
            type: .startup,
            startTime: cacheStartTime,
            endTime: Date(),
            attributes: ["cache_size": "10MB", "preload_items": "50"]
        )

        // Add overall startup metadata
        let totalDuration = Date().timeIntervalSince(overallStartTime)
        Embrace.client?.startupInstrumentation.addAttributesToTrace([
            "custom_initialization_complete": "true",
            "initialization_duration_ms": String(format: "%.2f", totalDuration * 1000),
            "initialization_steps": "3"
        ])

        print("Comprehensive startup instrumentation completed")
    }

    /// Example 5: Using Date() for time synchronization
    /// iOS SDK uses standard Date objects - no special time method needed
    static func timeSynchronizationExample() {
        // Capture start time using standard Date()
        let startTime = Date()

        // Perform operation
        Thread.sleep(forTimeInterval: 0.05)

        // Capture end time
        let endTime = Date()

        // The SDK internally uses EmbraceClock for consistent time tracking
        // You just use standard Date objects
        Embrace.client?.startupInstrumentation.recordCompletedChildSpan(
            name: "timed-operation",
            type: .startup,
            startTime: startTime,
            endTime: endTime,
            attributes: ["sync_method": "automatic"]
        )
    }
}
