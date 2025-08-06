//
//  Embrace_EcommerceApp.swift
//  Embrace Ecommerce
//
//  Created by Sergio Rodriguez on 8/6/25.
//

import SwiftUI
import EmbraceIO

@main
struct Embrace_EcommerceApp: App {
    init() {
        do {
            try Embrace
                .setup(
                    options: Embrace.Options(
                        appId: "YOUR_APP_ID", // TODO: Replace with actual App ID from Embrace Dashboard
                        logLevel: .default
                    )
                )
                .start()
        } catch let e {
            print("Error starting Embrace: \(e.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(CartManager())
                .environmentObject(MockDataService.shared)
        }
    }
}
