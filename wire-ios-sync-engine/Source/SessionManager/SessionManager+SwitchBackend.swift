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

import Foundation

extension SessionManager {
    public enum SwitchBackendError: Swift.Error {
        case loggedInAccounts
        case invalidBackend
    }

    public typealias CompletedSwitch = (Result<BackendEnvironment, Error>) -> Void

    public func canSwitchBackend() -> SwitchBackendError? {
        guard accountManager.accounts.isEmpty else {
            return .loggedInAccounts
        }

        return nil
    }

    public func switchBackend(to environment: BackendEnvironment) {
        self.environment = environment
        unauthenticatedSession = nil
    }

    public func fetchBackendEnvironment(
        at url: URL,
        completion: @escaping (Result<BackendEnvironment, Error>) -> Void
    ) {
        if let error = canSwitchBackend() {
            completion(.failure(error))
            return
        }
        dispatchGroup.enter()
        BackendEnvironment.fetchEnvironment(url: url) { result in
            DispatchQueue.main.async {
                switch result {
                case let .success(environment):
                    completion(.success(environment))
                case .failure:
                    completion(.failure(SwitchBackendError.invalidBackend))
                }
                self.dispatchGroup.leave()
            }
        }
    }
}
