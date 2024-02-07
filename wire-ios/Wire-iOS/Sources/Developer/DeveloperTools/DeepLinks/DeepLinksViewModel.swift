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

    enum Error: LocalizedError {

        case invalidLink

        var errorDescription: String? {
            switch self {
            case .invalidLink:
                return "The deeplink you have entered is invalid."
            }
        }

    }

    let onDismiss: (() -> Void)?

    @Published
    var isShowingAlert = false

    @Published
    var error: Error?

    // MARK: - Life cycle

    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    // MARK: - Actions

    func openLink(urlString: String) {
        guard 
            let url = URL(string: urlString),
            let _ = try? URLAction(url: url)
        else {
            error = .invalidLink
            isShowingAlert = true
            return
        }

        onDismiss?()
        _ = AppDelegate.shared.appRootRouter?.openDeepLinkURL(url)
    }
}
