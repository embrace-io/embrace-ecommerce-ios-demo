//
//  ContentView.swift
//  Embrace Ecommerce
//
//  Created by Sergio Rodriguez on 8/6/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthenticationManager

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .accessibilityIdentifier("mainTabView")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else {
                AuthenticationView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .trailing)
                    ))
            }
        }
        .accessibilityIdentifier("contentView")
        .animation(.easeInOut(duration: 0.5), value: authManager.isAuthenticated)
    }
}

#Preview {
    ContentView()
}
