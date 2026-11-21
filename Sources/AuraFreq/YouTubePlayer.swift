import SwiftUI
import WebKit

func youtubeID(_ input: String) -> String? {
    var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
    if !text.contains("://") { text = "https://" + text }
    guard let url = URLComponents(string: text), ["https", "http"].contains(url.scheme?.lowercased()),
          let host = url.host?.lowercased(), url.user == nil, url.password == nil else { return nil }
    let parts = url.path.split(separator: "/").map(String.init)
    var id: String?
    if host == "youtu.be" && parts.count == 1 { id = parts[0] }
    if ["youtube.com","www.youtube.com","m.youtube.com","music.youtube.com"].contains(host) {
        if parts == ["watch"] { id = url.queryItems?.first { $0.name == "v" }?.value }
        if parts.count == 2 && ["embed","live","shorts"].contains(parts[0]) { id = parts[1] }
    }
    guard let id, id.wholeMatch(of: /[A-Za-z0-9_-]{11}/) != nil else { return nil }
    return id
}

struct YouTubePlayer: NSViewRepresentable {
    let id: String
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = []
        let view = WKWebView(frame: .zero, configuration: config)
        let origin = URL(string: "https://com.huynhtancuong.aurafreq.native/")!
        let html = """
        <!doctype html><meta name="referrer" content="strict-origin-when-cross-origin">
        <style>html,body,iframe{width:100%;height:100%;margin:0;border:0;display:block;background:#111}</style>
        <iframe src="https://www.youtube.com/embed/\(id)?autoplay=1&amp;playsinline=1"
          title="YouTube" allow="autoplay; encrypted-media; fullscreen" allowfullscreen></iframe>
        """
        view.loadHTMLString(html, baseURL: origin)
        return view
    }
    func updateNSView(_ view: WKWebView, context: Context) {}
    static func dismantleNSView(_ view: WKWebView, coordinator: ()) {
        view.pauseAllMediaPlayback()
        view.stopLoading()
        view.loadHTMLString("", baseURL: nil)
    }
}
