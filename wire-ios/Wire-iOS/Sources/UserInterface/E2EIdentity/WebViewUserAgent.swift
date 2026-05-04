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

import AppAuth
import Foundation
import UIKit

class WebViewUserAgent: NSObject, OIDExternalUserAgent, WebAuthViewControllerDelegate {

    private let targetViewController: UIViewController
    private var session: OIDExternalUserAgentSession?
    private var webAuthViewController: WebAuthViewController?

    init(targetViewController: UIViewController) {
        self.targetViewController = targetViewController
    }

    func present(
        _ request: any OIDExternalUserAgentRequest,
        session: any OIDExternalUserAgentSession
    ) -> Bool {
        let url = request.externalUserAgentRequestURL().absoluteURL
        let webAuthViewController = WebAuthViewController(url: url)
        self.webAuthViewController = webAuthViewController
        webAuthViewController.delegate = self
        targetViewController.present(webAuthViewController, animated: true)
        self.session = session
        return true
    }

    func dismiss(
        animated: Bool,
        completion: @escaping () -> Void
    ) {
        targetViewController.presentedViewController?.dismiss(animated: animated) { [weak self] in
            self?.destroyWebAuthViewController()
            completion()
        }
    }

    func webAuthViewDidReceiveCallback(url: URL) {
        session?.resumeExternalUserAgentFlow(with: url)
        destroyWebAuthViewController()
    }

    func webAuthViewDidCancel() {
        session?.cancel()
        destroyWebAuthViewController()
    }

    func webAuthViewDidFail(error: any Error) {
        dismiss(animated: true) { [weak self] in
            self?.session?.failExternalUserAgentFlowWithError(error)
        }
    }

    private func destroyWebAuthViewController() {
        webAuthViewController?.wipeDataStore()
        webAuthViewController = nil
    }

}
