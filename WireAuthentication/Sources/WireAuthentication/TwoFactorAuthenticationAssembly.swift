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

import SwiftUI
import WireLogging
internal import WireAuthenticationUI
internal import WireAuthenticationLogic

public struct TwoFactorAuthenticationAssembly {

    public init() {}

    @MainActor
    public func assemble() -> UIViewController {
        let viewModel = TwoFactorAuthenticationViewModel(
            isTwoFactorAuthenticationEnabledUseCase: MockIsTwoFactorAuthenticationEnabledUseCase(isEnabled: true),
            getRegisteredAuthenticatorAppsUseCase: MockGetRegisteredAuthenticatorAppsUseCase(),
            getRecoveryCodesStatusUseCase: MockGetRecoveryCodesStatusUseCase(),
            logger: WireLogger.authentication
        )
        let controller = UIHostingController(rootView: TwoFactorAuthenticationView(viewModel: viewModel))

        viewModel.onShowAuthenticatorApps = { [weak controller] in
            let destination = UIHostingController(rootView: TwoFactorAuthenticationPlaceholderView(
                destination: .authenticatorApps
            ))
            destination.hidesBottomBarWhenPushed = true
            controller?.navigationController?.pushViewController(destination, animated: true)
        }
        viewModel.onShowRecoveryCodes = { [weak controller] in
            let destination = UIHostingController(rootView: TwoFactorAuthenticationPlaceholderView(
                destination: .recoveryCodes
            ))
            destination.hidesBottomBarWhenPushed = true
            controller?.navigationController?.pushViewController(destination, animated: true)
        }

        return controller
    }
}
