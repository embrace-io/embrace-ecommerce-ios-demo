import SwiftUI
import WebKit

struct WebViewDemoView: View {
    var body: some View {
        EmbraceWebView()
            .navigationTitle("WebView Demo")
            .navigationBarTitleDisplayMode(.inline)
            .embraceTrace("WebViewDemoView")
    }
}

// MARK: - WKWebView wrapper with Embrace log bridge

struct EmbraceWebView: UIViewRepresentable {
    static let handlerName = "embrace"

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: Self.handlerName)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isInspectable = true
        webView.navigationDelegate = context.coordinator

        if let url = Bundle.main.url(forResource: "index", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: - Coordinator (message handler + navigation delegate)

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == EmbraceWebView.handlerName else { return }

            guard let payload = message.body as? [String: Any] else {
                EmbraceService.shared.logWarning(
                    "webview.message.invalid",
                    properties: ["reason": "payload was not a dictionary"]
                )
                return
            }

            let eventType = payload["type"] as? String ?? "unknown"
            let severity = payload["severity"] as? String ?? "info"

            // Flatten all payload values into string properties for the log
            var properties: [String: String] = ["webview.event_type": eventType]
            for (key, value) in payload where key != "type" && key != "severity" {
                properties["webview.\(key)"] = "\(value)"
            }

            switch severity {
            case "error":
                EmbraceService.shared.logError("webview.event: \(eventType)", properties: properties)
            case "warning":
                EmbraceService.shared.logWarning("webview.event: \(eventType)", properties: properties)
            default:
                EmbraceService.shared.logInfo("webview.event: \(eventType)", properties: properties)
            }
        }

        // Log when the webview fails to load at all -- the "never loads" case
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            EmbraceService.shared.logError("webview.navigation.failed", properties: [
                "error": error.localizedDescription
            ])
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            EmbraceService.shared.logError("webview.navigation.provisional_failed", properties: [
                "error": error.localizedDescription
            ])
        }
    }

}

#Preview {
    NavigationStack {
        WebViewDemoView()
    }
}
