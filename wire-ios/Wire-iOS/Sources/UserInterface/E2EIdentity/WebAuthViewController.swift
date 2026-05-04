//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import Foundation
import SwiftUI
import UIKit
import WebKit
import WireCommonComponents
import WireDesign

protocol WebAuthViewControllerDelegate: AnyObject {

    func webAuthViewDidReceiveCallback(url: URL)
    func webAuthViewDidCancel()
    func webAuthViewDidFail(error: Error)

}

final class WebAuthViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    let url: URL
    weak var delegate: WebAuthViewControllerDelegate?

    private var urlLabel: URLLabel!

    private lazy var webView: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()

        // Don't cache anything (cookies, data, etc).
        webConfiguration.websiteDataStore = .nonPersistent()

        // Misc
        webConfiguration.dataDetectorTypes = []
        webConfiguration.mediaTypesRequiringUserActionForPlayback = .all

        let preferences = WKPreferences()
        preferences.isTextInteractionEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = false
        webConfiguration.preferences = preferences

        // Block JavaScript.
        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = false
        webConfiguration.defaultWebpagePreferences = webpagePreferences

        // Ensure no user scripts.
        let userContentController = WKUserContentController()
        userContentController.removeAllUserScripts()
        webConfiguration.userContentController = userContentController

        let customUserAgent = if let appVersion = Bundle.main.shortVersionString {
            "Wire E2EI \(appVersion)"
        } else {
            "Wire E2EI"
        }

        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.customUserAgent = customUserAgent
        webView.tintColor = .systemBlue
        webView.isInspectable = false
        webView.allowsLinkPreview = false
        webView.uiDelegate = self
        webView.navigationDelegate = self
        return webView
    }()

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        // Prevent auto dismissal.
        isModalInPresentation = true

        urlLabel = URLLabel(url: url)
        urlLabel.isUserInteractionEnabled = true
        urlLabel.isAccessibilityElement = true
        urlLabel.accessibilityLabel = L10n.Accessibility.WebAuth.UrlLabel.description
        urlLabel.accessibilityHint = L10n.Accessibility.WebAuth.UrlLabel.hint

        urlLabel.addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(urlLabelTapped)
            )
        )

        let navBar = UINavigationBar()
        navBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navBar)

        let navItem = UINavigationItem()
        navItem.titleView = urlLabel
        navItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        navBar.setItems([navItem], animated: false)

        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: 50)
        ])

        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let request = URLRequest(url: url)
        webView.load(request)
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
        guard let url = navigationAction.request.url else {
            return .cancel
        }

        switch url.scheme {
        case "https":
            // Only allow same host as original IDP url.
            guard url.host() == self.url.host() else {
                return .cancel
            }

            // Block all downloads.
            guard !navigationAction.shouldPerformDownload else {
                return .cancel
            }

            // Only allow standard internet traffic (no video, media,
            // av streaming, voip, etc etc)
            guard navigationAction.request.networkServiceType == .default else {
                return .cancel
            }

            return .allow

        case "wire":
            delegate?.webAuthViewDidReceiveCallback(url: url)
            return .cancel

        default:
            // Unsupported scheme.
            return .cancel
        }
    }

    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation!
    ) {
        if let currentURL = webView.url {
            urlLabel.url = currentURL
        }
    }

    func webView(
        _ webView: WKWebView,
        decideMediaCapturePermissionsFor origin: WKSecurityOrigin,
        initiatedBy frame: WKFrameInfo,
        type: WKMediaCaptureType
    ) async -> WKPermissionDecision {
        .deny
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: any Error
    ) {
        delegate?.webAuthViewDidFail(error: error)
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: any Error
    ) {
        delegate?.webAuthViewDidFail(error: error)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        delegate?.webAuthViewDidFail(error: Failure.webKitProcessTerminated)
    }

    @objc
    private func cancelButtonTapped() {
        delegate?.webAuthViewDidCancel()
    }

    @objc
    private func urlLabelTapped() {
        // Show the user the entire URL for them to verify.
        let view = WebAuthURLView(url: url.absoluteString)
        let viewController = UIHostingController(rootView: view)
        present(viewController, animated: true)
    }

    func wipeDataStore() {
        // Even though it's non persistent, clear it just to be safe.
        DispatchQueue.main.async { [weak self] in
            let types = WKWebsiteDataStore.allWebsiteDataTypes()
            self?.webView.configuration.websiteDataStore.removeData(
                ofTypes: types,
                modifiedSince: Date.distantPast
            ) {}
        }
    }

    enum Failure: Error {

        case webKitProcessTerminated

    }

}

// VoiceOver reads UILabel text content then the accessibility label
// you set. If the content is a long URL then the it's not a very
// good experience. This view wraps the label so if you set an
// accessibility label then VoiceOver will only read that label.

private final class URLLabel: UIView {

    var url: URL {
        didSet {
            label.text = url.absoluteString
        }
    }

    private let label: UILabel

    init(url: URL) {
        self.url = url
        self.label = UILabel()
        super.init(frame: .zero)
        label.text = url.absoluteString
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// To show the complete URL.

private struct WebAuthURLView: View {

    let url: String

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 40) {
            HStack {
                Spacer()
                Text(L10n.Localizable.EnrollE2eiCertificate.idpUrlTitle)
                    .font(.body)
                    .bold()

                Spacer()
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(ColorTheme.Base.secondaryText.color)
                }
            }

            ScrollView {
                Text(url)
                    .font(.body)
            }
        }
        .padding()
    }

}
