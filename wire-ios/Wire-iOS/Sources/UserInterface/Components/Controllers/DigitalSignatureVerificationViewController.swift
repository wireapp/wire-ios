//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import UIKit
import WebKit
import WireUtilities

// MARK: - DigitalSignatureVerificationError

enum DigitalSignatureVerificationError: Error {
    case postCodeRetry
    case authenticationFailed
    case otherError
}

// MARK: - DigitalSignatureVerificationViewController

final class DigitalSignatureVerificationViewController: UIViewController {
    // MARK: Lifecycle

    // MARK: - Init

    init(url: URL, completion: DigitalSignatureCompletion? = nil) {
        self.url = url
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    typealias DigitalSignatureCompletion = (_ result: Result<Void, Error>) -> Void

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadURL()
    }

    // MARK: Private

    // MARK: - Private Property

    private var completion: DigitalSignatureCompletion?

    private var webView = WKWebView(frame: .zero)
    private var url: URL?

    // MARK: - Private Method

    private func setupWebView() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        updateButtonMode()

        view.addSubview(webView)
        webView.fitIn(view: view)
    }

    private func updateButtonMode() {
        let buttonItem = UIBarButtonItem(
            title: L10n.Localizable.General.done,
            style: .done,
            target: self,
            action: #selector(onClose)
        )
        buttonItem.accessibilityIdentifier = "DoneButton"
        buttonItem.accessibilityLabel = L10n.Localizable.General.done
        buttonItem.tintColor = UIColor.black
        navigationItem.leftBarButtonItem = buttonItem
    }

    private func loadURL() {
        guard let url else {
            return
        }
        let request = URLRequest(url: url)
        webView.load(request)
    }

    @objc
    private func onClose() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: WKNavigationDelegate

extension DigitalSignatureVerificationViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard
            let url = navigationAction.request.url,
            let response = parseVerificationURL(url)
        else {
            decisionHandler(.allow)
            return
        }

        switch response {
        case .success:
            completion?(.success(()))
            decisionHandler(.cancel)

        case let .failure(error):
            completion?(.failure(error))
            decisionHandler(.cancel)
        }
    }

    func parseVerificationURL(_ url: URL) -> Result<Void, Error>? {
        let urlComponents = URLComponents(string: url.absoluteString)
        let postCode = urlComponents?.queryItems?
            .first(where: { $0.name == "postCode" })
        guard let  postCodeValue = postCode?.value else {
            return nil
        }
        switch postCodeValue {
        case "sas-success":
            return .success(())
        case "sas-error-authentication-failed":
            return .failure(DigitalSignatureVerificationError.authenticationFailed)
        default:
            return .failure(DigitalSignatureVerificationError.otherError)
        }
    }
}
