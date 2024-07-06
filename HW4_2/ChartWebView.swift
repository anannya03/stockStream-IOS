

import SwiftUI
import WebKit

struct ChartWebView: UIViewRepresentable {
    let htmlContent: String
    
    // Create the WKWebView and configure it
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false // Ensure the background is not opaque
        webView.backgroundColor = .clear // Set the background color to clear
        webView.navigationDelegate = context.coordinator // Set the navigation delegate
        return webView
    }
    
    // Load the HTML content when the view updates
    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(htmlContent, baseURL: nil) // Load the actual HTML string
    }
    
    // Coordinator for handling WebView navigation
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator class to handle web navigation
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: ChartWebView

        init(_ parent: ChartWebView) {
            self.parent = parent
        }
        
        // Example of intercepting a navigation
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView content loaded.")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
               print("WebView load failed with error: \(error.localizedDescription)")
           }
    }
}

