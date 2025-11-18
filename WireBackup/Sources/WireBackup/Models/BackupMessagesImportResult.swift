//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

public struct BackupMessagesImportResult {

    public let validationCount: ResultCount
    public let insertionCount: ResultCount
    public let rehydrationCount: ResultCount

    public init(
        validationCount: ResultCount,
        insertionCount: ResultCount,
        rehydrationCount: ResultCount
    ) {
        self.validationCount = validationCount
        self.insertionCount = insertionCount
        self.rehydrationCount = rehydrationCount
    }

}

public extension BackupMessagesImportResult {

    struct ResultCount {
        public let successCount: Int
        public let failureCount: Int

        public init(successCount: Int, failureCount: Int) {
            self.successCount = successCount
            self.failureCount = failureCount
        }
    }

}
