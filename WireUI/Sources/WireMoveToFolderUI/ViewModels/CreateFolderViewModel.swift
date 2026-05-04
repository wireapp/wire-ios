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

@MainActor
public final class CreateFolderViewModel: ObservableObject {

    // MARK: - Properties

    @Published private(set) var canCreate: Bool = false
    @Published var name: String = "" {
        didSet {
            canCreate = !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private let useCase: any CreateConversationFolderUseCaseProtocol

    // MARK: - Lifecycle

    public init(useCase: any CreateConversationFolderUseCaseProtocol) {
        self.useCase = useCase
    }

    // MARK: - Public Interface

    public func createFolder() async throws -> Folder {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw FolderCreationError.emptyName
        }

        return try await useCase.invoke(name: trimmedName)
    }
}

// MARK: - FolderCreationError

public enum FolderCreationError: LocalizedError {
    case emptyName

    public var errorDescription: String? {
        switch self {
        case .emptyName:
            "Folder name cannot be empty"
        }
    }
}
