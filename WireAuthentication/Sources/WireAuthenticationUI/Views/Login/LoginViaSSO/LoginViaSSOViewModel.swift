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

import Combine
import Foundation
import SwiftUI
import WireAuthenticationAPI

@MainActor
package final class LoginViaSSOViewModel: ObservableObject {

    package typealias Factory = CreateAuthenticationResultUseCaseFactory

    let ssoURL: URL
    private let factory: any Factory
    private let onResult: (Result<AuthenticationResult, Error>) -> Void
    private var cancellable: AnyCancellable?

    package init(
        factory: any Factory,
        bridge: WireAuthenticationBridge,
        ssoURL: URL,
        onResult: @escaping (Result<AuthenticationResult, Error>) -> Void
    ) {
        self.factory = factory
        self.ssoURL = ssoURL
        self.onResult = onResult
        self.cancellable = bridge.inboundEvents.sink { [weak self] in
            switch $0 {
            case let .ssoAuthenticationSuccess(
                userID,
                cookies
            ):
                Task { [weak self] in
                    await self?.handleSSOSuccess(
                        userID: userID,
                        cookies: cookies
                    )
                }

            case .ssoAutheticationFailure:
                self?.handleSSOFailure()

            default:
                break
            }
        }
    }

    private func handleSSOSuccess(
        userID: UUID,
        cookies: [HTTPCookie]
    ) async {
        do {
            let useCase = factory.createAuthenticationResultUseCase()
            let result = try await Task.detached {
                try await useCase.invoke(
                    userID: userID,
                    cookies: cookies,
                    accessToken: nil,
                    emailCredentials: nil
                )
            }.value
            onResult(.success(result))
        } catch {
            onResult(.failure(error))
        }
    }

    private func handleSSOFailure() {
        onResult(.failure(SSOAuthenticationError.unknown))
    }

}
