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
        webView.navigationDelegate = context.coordinator
        webView.loadHTMLString(Self.sampleHTML, baseURL: nil)
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

    // MARK: - Sample HTML with inline diagnostics script

    /// Simulates the kind of article page NYTimes would serve in a webview.
    /// The inline <script> is the "copypasta" snippet concept from the conversation.
    static let sampleHTML: String = """
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        body { font-family: -apple-system, sans-serif; padding: 16px; background: #fff; color: #1a1a1a; }
        h1 { font-size: 22px; line-height: 1.3; }
        .meta { color: #666; font-size: 13px; margin-bottom: 16px; }
        p { font-size: 16px; line-height: 1.6; }
        img { max-width: 100%; height: auto; border-radius: 8px; margin: 12px 0; }
        .status { position: fixed; bottom: 0; left: 0; right: 0; background: #f0f0f0; padding: 8px 16px; font-size: 11px; color: #888; }
      </style>
    </head>
    <body>
      <h1>Sample Article: The Future of Mobile Observability</h1>
      <div class="meta">Published Apr 2, 2026 &middot; 4 min read</div>
      <p>
        When users open an article inside a native app, the content is rendered
        in a webview. The native app has no visibility into whether the page
        loaded correctly, how long it took, or whether the content is empty.
      </p>
      <p>
        This demo page includes a small inline script that measures document
        load timing, detects empty content, and sends diagnostics back to the
        native app via <code>window.webkit.messageHandlers</code>.
      </p>
      <p>
        The native side receives these messages and emits them as Embrace Logs,
        which appear in the session timeline alongside all other app telemetry.
      </p>
      <img src="https://picsum.photos/600/300" alt="placeholder" />
      <p>
        This is exactly the kind of pre-rendered article content that might be
        served from a local cache or a content delivery service.
      </p>

      <div class="status" id="status">Collecting diagnostics...</div>

      <!-- Embrace WebView diagnostics snippet -->
      <script>
      ((d, w, p) => {
        const post = (payload) => {
          try {
            w.webkit.messageHandlers.embrace.postMessage(payload);
          } catch (e) {
            // Not in a WKWebView or handler not registered -- silently ignore
          }
        };

        // 1. Document load timing
        const onLoad = () => {
          const t = p.timing || {};
          const navEntry = (p.getEntriesByType && p.getEntriesByType('navigation')[0]) || {};

          const domContentLoaded = navEntry.domContentLoadedEventEnd || (t.domContentLoadedEventEnd - t.navigationStart);
          const loadComplete = navEntry.loadEventEnd || (t.loadEventEnd - t.navigationStart);
          const ttfb = navEntry.responseStart || (t.responseStart - t.navigationStart);
          const domInteractive = navEntry.domInteractive || (t.domInteractive - t.navigationStart);

          post({
            type: "doc_load",
            ttfb_ms: Math.round(ttfb),
            dom_interactive_ms: Math.round(domInteractive),
            dom_content_loaded_ms: Math.round(domContentLoaded),
            load_complete_ms: Math.round(loadComplete),
            url: d.location.href
          });

          d.getElementById('status').textContent =
            'Load: ' + Math.round(loadComplete) + 'ms | TTFB: ' + Math.round(ttfb) + 'ms';
        };

        if (d.readyState === 'complete') {
          setTimeout(onLoad, 0);
        } else {
          w.addEventListener('load', () => setTimeout(onLoad, 0));
        }

        // 2. Empty content detection
        setTimeout(() => {
          const body = d.body;
          const textLength = (body.innerText || '').trim().length;
          const imgCount = body.querySelectorAll('img').length;
          if (textLength < 50 && imgCount === 0) {
            post({
              type: "empty_content",
              severity: "error",
              text_length: textLength,
              img_count: imgCount,
              url: d.location.href
            });
          }
        }, 2000);

        // 3. Unhandled errors
        w.addEventListener('error', (e) => {
          post({
            type: "js_error",
            severity: "error",
            message: e.message || 'unknown',
            filename: e.filename || '',
            lineno: e.lineno || 0,
            colno: e.colno || 0
          });
        });

        // 4. Resource load failures (images, scripts, etc.)
        d.addEventListener('error', (e) => {
          if (e.target && e.target.tagName) {
            post({
              type: "resource_error",
              severity: "warning",
              tag: e.target.tagName,
              src: e.target.src || e.target.href || ''
            });
          }
        }, true);

      })(document, window, performance);
      </script>
    </body>
    </html>
    """
}

#Preview {
    NavigationStack {
        WebViewDemoView()
    }
}
