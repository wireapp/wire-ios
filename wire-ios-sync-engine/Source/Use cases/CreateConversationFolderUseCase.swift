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

import WireDataModel

public struct CreateConversationFolderUseCase {

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    public init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Public Interface

    public func invoke(with name: String) async throws -> LabelType? {
        try await context.perform {
            var created = false
            let label = Label.fetchOrCreate(
                remoteIdentifier: UUID(),
                create: true,
                in: context,
                created: &created
            )
            label?.name = name
            label?.kind = .folder

            do {
                try context.save()
            } catch {
                throw error
            }

            return label
        }
    }

}
