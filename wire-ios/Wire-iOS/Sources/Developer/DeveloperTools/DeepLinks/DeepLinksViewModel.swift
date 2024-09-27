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
import WireSyncEngine

final class DeepLinksViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        router: AppRootRouter? = nil,
        onDismiss: @escaping (_ completion: @escaping () -> Void) -> Void = { $0() }
    ) {
        self.router = router
        self.onDismiss = onDismiss
    }

    // MARK: Internal

    enum Error: LocalizedError {
        case invalidLink

        // MARK: Internal

        var errorDescription: String? {
            switch self {
            case .invalidLink:
                "The deeplink you have entered is invalid."
            }
        }
    }

    let router: AppRootRouter?
    let onDismiss: (_ completion: @escaping () -> Void) -> Void

    @Published var isShowingAlert = false

    @Published var error: Error?

    // MARK: - Actions

    func openLink(urlString: String) {
        guard
            let url = URL(string: urlString),
            (try? URLAction(url: url)) != nil
        else {
            error = .invalidLink
            isShowingAlert = true
            return
        }

        onDismiss {
            _ = self.router?.openDeepLinkURL(url)
        }
    }
}
