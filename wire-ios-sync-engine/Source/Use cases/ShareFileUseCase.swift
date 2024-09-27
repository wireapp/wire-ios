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

// MARK: - ShareFileUseCaseProtocol

// sourcery: AutoMockable
public protocol ShareFileUseCaseProtocol {
    /// Share the debug report with the given conversations
    ///
    /// - Parameters:
    ///   - logFileMetadata: log file metadata
    ///   - conversations: list of conversations to share the debug report with

    func invoke(
        fileMetadata: ZMFileMetadata,
        conversations: [ZMConversation]
    )
}

// MARK: - ShareFileUseCase

public struct ShareFileUseCase: ShareFileUseCaseProtocol {
    private let contextProvider: ContextProvider

    public init(contextProvider: ContextProvider) {
        self.contextProvider = contextProvider
    }

    public func invoke(
        fileMetadata: ZMFileMetadata,
        conversations: [ZMConversation]
    ) {
        contextProvider.viewContext.perform {
            for conversation in conversations {
                do {
                    try conversation.appendFile(with: fileMetadata)
                } catch {
                    WireLogger.system.warn("Failed to append file. Reason: \(error.localizedDescription)")
                }
            }
        }
    }
}
