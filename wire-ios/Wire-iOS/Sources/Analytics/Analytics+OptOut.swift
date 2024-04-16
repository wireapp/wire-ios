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
import WireDataModel

extension Analytics {

    /// Opt the user out of sending analytics data
    var isOptedOut: Bool {
        get {
            guard let provider = provider else { return true }
            return provider.isOptedOut
        }

        set {
            if newValue && (provider?.isOptedOut ?? false) {
                return
            }

            if newValue {
                provider?.flush {
                    self.provider?.isOptedOut = newValue
                    self.provider = nil
                }
            } else {
                provider = AnalyticsProviderFactory.shared.analyticsProvider()

                if let user = SelfUser.provider?.providedSelfUser {
                    selfUser = user
                } else {
                    assertionFailure("expected available 'user'!")
                    selfUser = nil
                }
            }
        }
    }
}
