import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    
    let urlString: String?
    
    func makeUIView(context: Context) -> WebView.UIViewType {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let stringParam = urlString {
            if let url = URL(string: stringParam) {
                let request = URLRequest(url: url)
                uiView.load(request)
            }
        }
    }
}
