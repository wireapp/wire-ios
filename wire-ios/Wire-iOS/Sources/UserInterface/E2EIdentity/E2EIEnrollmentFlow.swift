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
import WireRequestStrategy
import WireReusableUIComponents

@MainActor
final class E2EIEnrollmentFlow {

    private let oauthUseCase: OAuthUseCaseInterface
    private let targetVC: () -> UIViewController
    private var activityIndicator: BlockingActivityIndicator?

    init(
        oauthUseCase: OAuthUseCaseInterface,
        targetVC: @escaping () -> UIViewController
    ) {
        self.oauthUseCase = oauthUseCase
        self.targetVC = targetVC
    }

    func showActivityIndicator() {
        guard
            activityIndicator == nil,
            let window = targetVC().view.window
        else { return }

        activityIndicator = BlockingActivityIndicator(view: window)
        activityIndicator?.start()
    }

    func dismissActivityIndicator() {
        activityIndicator?.stop()
        activityIndicator = nil
    }

    func authenticate(_ parameters: OAuthParameters) async throws -> OAuthResponse {
        try await oauthUseCase.invoke(
            parameters: parameters,
            onWebViewPresenting: { [weak self] in self?.dismissActivityIndicator() },
            onWebViewDismissed: { [weak self] in self?.showActivityIndicator() }
        )
    }
}
