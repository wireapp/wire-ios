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

public protocol FeatureChangeActions {

    func enrollCertificate()

    func postponeReminder()

}

/// TODO: Add tests https://wearezeta.atlassian.net/browse/WPB-6039
public class E2eIFeatureChangeActionsHandler: NSObject, FeatureChangeActions {

    // MARK: - Properties

    private var enrollE2eICertificate: EnrollE2eICertificateUseCaseInterface?

    // MARK: - Life cycle

    public init(enrollE2eICertificate: EnrollE2eICertificateUseCaseInterface?) {
        self.enrollE2eICertificate = enrollE2eICertificate
    }

    public func enrollCertificate() {
    /// TODO: https://wearezeta.atlassian.net/browse/WPB-6039
    }

    public func postponeReminder() {

    }

}
