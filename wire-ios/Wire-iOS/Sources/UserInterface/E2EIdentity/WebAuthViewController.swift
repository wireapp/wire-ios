//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import UIKit
import WebKit
import WireCommonComponents

protocol WebAuthViewControllerDelegate: AnyObject {

    func webAuthViewDidReceiveCallback(url: URL)
    func webAuthViewDidCancel()

}

class WebAuthViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    let url: URL
    weak var delegate: WebAuthViewControllerDelegate?

    private let urlLabel = UILabel()

    private lazy var webView: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()

        // Don't cache anything (cookies, data, etc).
        webConfiguration.websiteDataStore = .nonPersistent()

        // Misc
        webConfiguration.dataDetectorTypes = []
        webConfiguration.mediaTypesRequiringUserActionForPlayback = .all

        let preferences = WKPreferences()
        preferences.isTextInteractionEnabled = false
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        // Prevent auto dismissal.
        isModalInPresentation = true

        urlLabel.text = url.absoluteString
        urlLabel.lineBreakMode = .byTruncatingTail
        urlLabel.isUserInteractionEnabled = true
        urlLabel.showsExpansionTextWhenTruncated = true
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
            urlLabel.text = currentURL.absoluteString
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

    @objc
    private func cancelButtonTapped() {
        delegate?.webAuthViewDidCancel()
    }

    @objc
    private func urlLabelTapped() {
        // Show the user the entire URL for them to verify.
        let viewController = WebAuthURLViewController(url: url)
        present(viewController, animated: true)
    }

    func wipeDataStore() {
        // Even though it's non persistent, clear it just to be safe.
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        webView.configuration.websiteDataStore.removeData(
            ofTypes: types,
            modifiedSince: Date.distantPast
        ) {}
    }

}

private final class WebAuthURLViewController: UIViewController {

    let url: URL

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let textView = UITextView()
        textView.text = url.absoluteString
        textView.font = .preferredFont(forTextStyle: .body)
        textView.contentInset = UIEdgeInsets(
            top: 20,
            left: 20,
            bottom: 20,
            right: 20
        )

        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

}
