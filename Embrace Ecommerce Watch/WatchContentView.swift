//
//  WatchContentView.swift
//  Embrace Ecommerce Watch
//
//  Created by Sergio Rodriguez on 3/27/26.
//

import SwiftUI
import EmbraceIO

struct WatchContentView: View {
    @State private var statusMessage = "Embrace SDK Active"

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Embrace Watch")
                    .font(.headline)

                Text(statusMessage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Divider()

                Button("Log Breadcrumb") {
                    Embrace.client?.add(event: .breadcrumb("watchOS breadcrumb tap"))
                    statusMessage = "Breadcrumb logged"
                }

                Button("Log Error") {
                    Embrace.client?.log(
                        "watchOS test error",
                        severity: .error,
                        attributes: ["source": "watch_crash_test"]
                    )
                    statusMessage = "Error logged"
                }

                Divider()

                Button("Force Crash") {
                    forceCrash()
                }
                .foregroundColor(.red)
                .accessibilityIdentifier("watch-force-crash-button")
            }
            .padding()
        }
    }

    @inline(never)
    private func forceCrash() {
        Embrace.client?.log(
            "watchOS crash test triggered",
            severity: .error,
            attributes: [
                "crash_type": "watchos_manual_test",
                "trigger": "watch_crash_button"
            ]
        )
        Embrace.client?.add(event: .breadcrumb("watchOS force crash triggered"))
        Embrace.client?.crash()
    }
}

#Preview {
    WatchContentView()
}
