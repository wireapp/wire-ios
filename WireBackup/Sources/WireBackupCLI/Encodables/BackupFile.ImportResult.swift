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

@preconcurrency import KaliumBackup
import WireBackup

extension BackupFile {

    struct ImportResult: Encodable {

        let totalPagesCount: Int32?
        let users: [BackupUserModel]
        let conversations: [BackupConversationModel]
        let messages: [BackupMessageModel]

        init(_ importResult: BackupImportResult.Success) throws {

            let pagers = importResult.pager
            guard let usersPager = pagers.usersPager as? BackupImportDataPager<BackupUser> else {
                throw InitializationError.some("Unexpected user pager type: \(String(describing: pagers.usersPager))")
            }
            guard let conversationsPager = pagers.conversationsPager as? BackupImportDataPager<BackupConversation> else {
                throw InitializationError.some("Unexpected conversation pager type: \(String(describing: pagers.conversationsPager))")
            }
            guard let messagesPager = pagers.messagesPager as? BackupImportDataPager<BackupMessage> else {
                throw InitializationError.some("Unexpected message pager type: \(String(describing: pagers.messagesPager))")
            }

            self.totalPagesCount = importResult.pager.totalPagesCount
            self.users = [BackupUser](usersPager)
                .compactMap(BackupUserModel.init)
                .sorted { $0.name < $1.name }
            self.conversations = [BackupConversation](conversationsPager)
                .compactMap(BackupConversationModel.init)
                .sorted { $0.name < $1.name }
            self.messages = [BackupMessage](messagesPager)
                .compactMap(BackupMessageModel.init)
                .sorted { $0.creationDate < $1.creationDate }

        }

    }

}
