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

import CoreData
import Foundation
import WireCellsAPI

extension WireCellsMessageAttachmentsDraftsLocalStore: WireCellsMessageAttachmentDraftDao {

    public func getAttachment(draftID: WireCellsMessageAttachmentDraftID) async throws(WireCellsMessageAttachmentDraftDaoError)
        -> WireCellsMessageAttachmentDraft? {
            do {
                return try await context.perform { [context] in
                    fatalError("Not implemented")
                }
            } catch {
                throw .genericError(error)
            }
        }

    public func getAttachments(conversationID: WireCellsConversationID) async throws(WireCellsMessageAttachmentDraftDaoError)
    -> [WireCellsMessageAttachmentDraft] {
        do {
            return try await context.perform { [context] in
                fatalError("Not implemented")
            }
        } catch {
            throw .genericError(error)
        }
    }

    public func deleteAttachment(draftID: WireCellsMessageAttachmentDraftID) async throws(
        WireCellsMessageAttachmentDraftDaoError
    ) {
        do {
            return try await context.perform { [context] in
                fatalError("Not implemented")
            }
        } catch {
            throw .genericError(error)
        }
    }

    public func deleteAttachments(conversationID: WireCellsConversationID) async throws(
        WireCellsMessageAttachmentDraftDaoError
    ) {
        do {
            return try await context.perform { [context] in
                fatalError("Not implemented")
            }
        } catch {
            throw .genericError(error)
        }
    }

    public func observeAttachments(conversationID: WireCellsConversationID)
    -> AsyncStream<[WireCellsMessageAttachmentDraft]> {
        do {
            fatalError("Not implemented")
        } catch {
            throw .genericError(error)
        }
    }

    public func addAttachment(
        uuid: UUID,
        versionID: String,
        conversationID: WireCellsConversationID,
        mimeType: String,
        fileName: String,
        fileSize: Int64,
        dataPath: String,
        nodePath: String,
        status: String,
        assetWidth: Int?,
        assetHeight: Int?,
        assetDuration: Int64?
    ) async throws(WireCellsMessageAttachmentDraftDaoError) -> WireCellsMessageAttachmentDraft {
        do {
            return try await context.perform { [context] in

            }
        } catch {
            throw .genericError(error)
        }
    }

    public func updateUploadStatus(
        draftID: WireCellsMessageAttachmentDraftID,
        status: String
    ) async throws(WireCellsMessageAttachmentDraftDaoError) {
        do {
            return try await context.perform { [context] in

            }
        } catch {
            throw .genericError(error)
        }
    }
}
