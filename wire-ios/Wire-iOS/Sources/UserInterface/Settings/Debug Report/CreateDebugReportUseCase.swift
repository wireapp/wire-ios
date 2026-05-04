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

import Foundation
import WireLogging

// sourcery: AutoMockable
protocol CreateDebugReportUseCaseProtocol {
    func invoke() async throws -> URL
}

final class CreateDebugReportUseCase: CreateDebugReportUseCaseProtocol {

    private let logsProvider: LogFilesProviding

    init(logsProvider: LogFilesProviding = LogFilesProvider()) {
        self.logsProvider = logsProvider
    }

    func invoke() async throws -> URL {
        try await Task.detached(priority: .userInitiated) { [logsProvider] in
            try logsProvider.generateLogFilesZip()
        }.value
    }
}
