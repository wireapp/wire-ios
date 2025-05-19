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

import Foundation
import Collections
import WireCellsAPI
@preconcurrency import Combine

struct Draft: Hashable, Sendable {
    let id: WireCellsNodeID
    let assetURL: URL
    var status: WireCellsUploadStatus
}

actor DraftsRepository {

    typealias CellName = String

    private var drafts: CurrentValueSubject<[CellName: OrderedDictionary<WireCellsNodeID,Draft>], Never> = .init([:])
    private var continuations: [UUID: AsyncStream<[Draft]>.Continuation] = [:]
    private var uploadManager: any WireCellsNodeUploadManagerProtocol

    init(uploadManager: any WireCellsNodeUploadManagerProtocol) {
        self.uploadManager = uploadManager
    }

    deinit {
        continuations.values.forEach { $0.finish() }
    }

    func add(assetURL: URL, assetSize: UInt64, cellName: String, fileName: String) async throws {
        let draft = Draft(
            id: .new(),
            assetURL: assetURL,
            status: .uploading(progress: 0)
        )
        drafts.value[cellName, default: [:]][draft.id] = draft

        do {
            let (_, stream) = try await uploadManager.upload(
                id: draft.id,
                assetPath: assetURL,
                assetSize: assetSize,
                destNodePath: "\(cellName)/\(fileName)"
            )
            for await status in stream {
                setStatus(status, cellName: cellName, id: draft.id)
            }

        } catch {
            setStatus(.failed, cellName: cellName, id: draft.id)
        }
    }

    func drafts(for cellName: CellName) -> AsyncStream<[Draft]> {
        let continuationID = UUID()
        let (stream, continuation) = AsyncStream.makeStream(of: [Draft].self, bufferingPolicy: .bufferingOldest(0))

        let cancellable = drafts.sink { drafts in
            let result = drafts[cellName] ?? [:]
            continuation.yield(Array(result.values))
        }
        continuation.onTermination = { continuation in
            cancellable.cancel()

            Task { [weak self] in
                await self?.removeContinuation(for: continuationID)
            }
        }

        continuations[continuationID] = continuation

        return stream
    }

    private func removeContinuation(for uuid: UUID) async{
        continuations[uuid] = nil
    }

    private func setStatus(_ status: WireCellsUploadStatus, cellName: CellName, id: WireCellsNodeID) {
        drafts.value[cellName]?[id]?.status = status
    }

}

private extension WireCellsNodeID {
    static func new() -> WireCellsNodeID {
        WireCellsNodeID(uuid: UUID(), versionID: UUID())
    }
}
