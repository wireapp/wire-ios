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

public final class PushSupportedProtocolsAction: EntityAction {

    public typealias Result = Void

    public enum Failure: Error, Equatable {
        case unknownError(code: Int, label: String, message: String)
        case requestEndpointUnavailable
    }

    public let supportedProtocols: Set<MessageProtocol>
    public var resultHandler: ResultHandler?

    public init(
        supportedProtocols: Set<MessageProtocol>,
        resultHandler: ResultHandler? = nil
    ) {
        self.supportedProtocols = supportedProtocols
        self.resultHandler = resultHandler
    }

}
