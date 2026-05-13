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

import UIKit
import WebKit
import WireUtilities

// MARK: - Error states

enum DigitalSignatureVerificationError: Error {
    case postCodeRetry
    case authenticationFailed
    case otherError
}

final class DigitalSignatureVerificationViewController: UIViewController {

    typealias DigitalSignatureCompletion = (_ result: Result<Void, Error>) -> Void

    // MARK: - Private Property

    private let viewModel: DigitalSignatureVerificationViewModel
    private var completion: DigitalSignatureCompletion?

    private var webView = WKWebView(frame: .zero)

    // MARK: - Init

    init(url: URL, completion: DigitalSignatureCompletion? = nil) {
        self.viewModel = DigitalSignatureVerificationViewModel(url: url)
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        loadURL()
    }

    // MARK: - Private Method

    private func setupWebView() {
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        updateButtonMode()

        view.addSubview(webView)
        webView.fitIn(view: view)
    }

    private func updateButtonMode() {
        let displayState = viewModel.displayState
        let buttonItem = UIBarButtonItem(
            title: displayState.doneButtonTitle,
            style: .done,
            target: self,
            action: #selector(onClose)
        )
        buttonItem.accessibilityIdentifier = displayState.doneButtonAccessibilityIdentifier
        buttonItem.accessibilityLabel = displayState.doneButtonTitle
        buttonItem.tintColor = UIColor.black
        navigationItem.leftBarButtonItem = buttonItem
    }

    private func loadURL() {
        webView.load(viewModel.request)
    }

    @objc
    private func onClose() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - WKNavigationDelegate

extension DigitalSignatureVerificationViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        switch viewModel.route(for: url) {
        case .verificationSucceeded:
            completion?(.success(()))
            decisionHandler(.cancel)
        case let .verificationFailed(error):
            completion?(.failure(error))
            decisionHandler(.cancel)
        case .none:
            decisionHandler(.allow)
        }
    }
}
