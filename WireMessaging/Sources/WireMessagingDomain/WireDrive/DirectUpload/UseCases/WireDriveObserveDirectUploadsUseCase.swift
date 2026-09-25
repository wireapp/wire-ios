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

package import Combine
package import Foundation

/// Sole owner of `WireDriveDirectUploadTrackerProtocol`'s state: the manager pushes computed
/// `WireDriveDirectUploadItem`s here, and every observer (tracker sheet, folder listings) reads from
/// here. One shared instance, handed to both sides by the factory.
@MainActor
package final class WireDriveObserveDirectUploadsUseCase: WireDriveObserveDirectUploadsUseCaseProtocol,
    WireDriveDirectUploadTrackerProtocol {

    private let trackedItems = CurrentValueSubject<[UUID: WireDriveDirectUploadItem], Never>([:])

    package init() {}

    // MARK: - WireDriveObserveDirectUploadsUseCaseProtocol

    package func invoke() -> AnyPublisher<WireDriveDirectUploadsSummary, Never> {
        summaryPublisher
    }

    // MARK: - WireDriveDirectUploadTrackerProtocol (reading)

    package var summary: WireDriveDirectUploadsSummary {
        WireDriveDirectUploadsSummary(items: Array(trackedItems.value.values))
    }

    package var summaryPublisher: AnyPublisher<WireDriveDirectUploadsSummary, Never> {
        trackedItems
            .map { WireDriveDirectUploadsSummary(items: Array($0.values)) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    package func publisher(uploadID: UUID) -> AnyPublisher<WireDriveDirectUploadItem?, Never> {
        trackedItems
            .map { $0[uploadID] }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    package func publisher(folderPath: String) -> AnyPublisher<[WireDriveDirectUploadItem], Never> {
        trackedItems
            .map { items in
                items.values
                    .filter { $0.destinationFolderPath == folderPath }
                    .sorted { $0.createdAt < $1.createdAt }
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    // MARK: - WireDriveDirectUploadTrackerProtocol (writing)

    package func replaceAll(with items: [WireDriveDirectUploadItem]) {
        trackedItems.value = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
    }

    package func upsert(_ items: [WireDriveDirectUploadItem]) {
        var current = trackedItems.value
        var didChange = false

        for item in items where current[item.id] != item {
            current[item.id] = item
            didChange = true
        }

        guard didChange else { return }
        trackedItems.value = current
    }

    /// Updates only the progress of an already-tracked upload.
    package func updateProgress(uploadID: UUID, progress: Float) {
        guard let existing = trackedItems.value[uploadID] else { return }

        switch existing.status {
        case .queued, .uploading:
            break
        case .uploaded, .failed, .cancelled:
            return
        }

        let clamped = min(max(progress, 0), 1)
        let status: WireDriveDirectUploadItem.Status = clamped > 0 ? .uploading(progress: clamped) : .queued

        var current = trackedItems.value
        current[uploadID] = existing.with(status: status)
        trackedItems.value = current
    }

    package func removeAll() {
        guard !trackedItems.value.isEmpty else { return }
        trackedItems.value = [:]
    }
}

// MARK: - WireDriveDirectUploadItem status transition

private extension WireDriveDirectUploadItem {

    func with(status: WireDriveDirectUploadItem.Status) -> WireDriveDirectUploadItem {
        WireDriveDirectUploadItem(
            id: id,
            batchID: batchID,
            nodeID: nodeID,
            fileName: fileName,
            fileSize: fileSize,
            destinationFolderPath: destinationFolderPath,
            status: status,
            createdAt: createdAt,
            isRetryable: status.error?.isRetryable ?? false
        )
    }
}
