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

/// A configuration for the *MLS* feature.

public struct MLSFeatureConfig: Equatable, Codable, Sendable {

    /// The feature's status.

    public let status: FeatureConfigStatus

    /// The ids of users who have the option to create new MLS groups.

    public let protocolToggleUsers: Set<UUID>

    /// The default protocol to use when creating a conversation.

    public let defaultProtocol: MessageProtocol

    /// The list of cipher suites that are allowed to be used with mls.

    public let allowedCipherSuites: [MLSCipherSuite]

    /// The default cipher suite used when creating a new MLS group.

    public let defaultCipherSuite: MLSCipherSuite

    /// The list of supported message protocols.

    public let supportedProtocols: Set<MessageProtocol>

    public init(
        status: FeatureConfigStatus,
        protocolToggleUsers: Set<UUID>,
        defaultProtocol: MessageProtocol,
        allowedCipherSuites: [MLSCipherSuite],
        defaultCipherSuite: MLSCipherSuite,
        supportedProtocols: Set<MessageProtocol>
    ) {
        self.status = status
        self.protocolToggleUsers = protocolToggleUsers
        self.defaultProtocol = defaultProtocol
        self.allowedCipherSuites = allowedCipherSuites
        self.defaultCipherSuite = defaultCipherSuite
        self.supportedProtocols = supportedProtocols
    }

}
