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

/// Types of a user client.

public enum UserClientType: String, Codable, Sendable {

    /// A client intended to be used for long periods of time,
    /// such as a mobile device or web application.

    case permanent

    /// A client intended to be used for a short period of time,
    /// such as a web application when the user chooses not to be
    /// remembered.

    case temporary

    /// A special type of client which is used to store a copy of
    /// all messages you send or receive.

    case legalhold

}
