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
import WireTransport

protocol SwitchBackendURLActionProcessorDelegate: AnyObject {

    func switchBackend(to environment: BackendEnvironment) throws

}

struct SwitchBackendURLActionProcessor: URLActionProcessor {

    weak var delegate: SwitchBackendURLActionProcessorDelegate?

    func process(
        urlAction: URLAction,
        delegate: (any PresentationDelegate)?
    ) {
        guard
            case .accessBackend(let url) = urlAction,
            let presentationDelegate = delegate,
            let delegate = self.delegate
        else {
            return
        }

        BackendEnvironment.fetchEnvironment(url: url) { result in
            switch result {
            case .success(let environment):
                presentationDelegate.requestUserConfirmationToSwitchBackend(environment) { didConfirm in
                    if didConfirm {
                        do {
                            try delegate.switchBackend(to: environment)
                            presentationDelegate.didSwitchBackend(environment: environment)
                        } catch {
                            print("Failed to switch backend: \(error)")
                        }
                    }
                }
            case .failure(let error):
                // Ask delegate to show error
                break
            }
        }
    }


}
