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

extension ZMMessage {
    public enum ProcessingError: LocalizedError {
        case missingManagedObjectContext
        case failedToProcessMessageData(reason: String)

        // MARK: Public

        public var errorDescription: String? {
            switch self {
            case .missingManagedObjectContext:
                "Missing managed object context."
            case let .failedToProcessMessageData(reason):
                "Failed to process message data. Reason: \(reason)"
            }
        }
    }
}
