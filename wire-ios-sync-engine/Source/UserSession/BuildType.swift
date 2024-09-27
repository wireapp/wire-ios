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

import WireSystem

enum BuildType: Equatable {
    case production
    case alpha
    case beta
    case development
    case `internal`
    case releaseCandidate
    case custom(bundleID: String)

    // MARK: Lifecycle

    init(bundleID: String) {
        switch bundleID {
        case BuildType.production.bundleID:
            self = .production

        case BuildType.alpha.bundleID:
            self = .alpha

        case BuildType.beta.bundleID:
            self = .beta

        case BuildType.development.bundleID:
            self = .development

        case BuildType.internal.bundleID:
            self = .internal

        case BuildType.releaseCandidate.bundleID:
            self = .releaseCandidate

        default:
            self = .custom(bundleID: bundleID)
        }
    }

    // MARK: Internal

    var certificateName: String {
        switch self {
        case .production:
            "com.wire"

        case .alpha,
             .beta,
             .development,
             .internal,
             .releaseCandidate:
            bundleID

        case let .custom(bundleID):
            bundleID
        }
    }

    var bundleID: String {
        switch self {
        case .production:
            "com.wearezeta.zclient.ios"

        case .alpha:
            "com.wearezeta.zclient.alpha"

        case .beta:
            "com.wearezeta.zclient.ios.beta"

        case .development:
            "com.wearezeta.zclient.development"

        case .internal:
            "com.wearezeta.zclient.internal"

        case .releaseCandidate:
            "com.wearezeta.zclient.rc"

        case let .custom(bundleID):
            bundleID
        }
    }
}
