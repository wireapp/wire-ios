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

import Combine
import Foundation
import SwiftUI
import WireLogging

@MainActor
package protocol Router {

    func pop()
    func popToRoot()

    func navigate(to destination: some Hashable)

    func presentSheet(_ modalDestination: RootViewSheet)

    func dismissSheet()

    func presentAlert(_ alert: Alert)

}

package extension Router {

    func presentAlert(for error: any Error) {
        WireLogger.authentication.error("router received unhandled error: \(String(describing: error))")
        presentAlert(.general(for: error))
    }

}
