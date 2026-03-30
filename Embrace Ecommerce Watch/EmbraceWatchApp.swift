//
//  EmbraceWatchApp.swift
//  Embrace Ecommerce Watch
//
//  Created by Sergio Rodriguez on 3/27/26.
//

import SwiftUI
import EmbraceIO

@main
struct EmbraceWatchApp: App {
    init() {
        configureEmbrace()
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }

    private func configureEmbrace() {
        do {
            let options = Embrace.Options(
                appId: "hca5g",
                logLevel: .debug
            )

            try Embrace
                .setup(options: options)
                .start()

            try? Embrace.client?.metadata.addProperty(
                key: "platform",
                value: "watchOS",
                lifespan: .permanent
            )

            try? Embrace.client?.metadata.addProperty(
                key: "app_type",
                value: "watchos_crash_test",
                lifespan: .permanent
            )

            print("[Embrace] watchOS SDK started")
        } catch {
            print("[Embrace] Failed to start: \(error.localizedDescription)")
        }
    }
}
