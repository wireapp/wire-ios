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
@preconcurrency import Photos
package import PhotosUI
package import SwiftUI
import UniformTypeIdentifiers
import WireLogging
package import WireMessagingDomain

private typealias Strings = L10n.Localizable.Conversation.WireCells.Files.Upload

package extension FilesViewModel {

    var uploadDestinationPath: String? {
        guard !isBrowsing, !isRecycleBin else { return nil }
        return navigationPath.last?.filePath ?? cellName
    }

    private var isDriveDirectUploadsEnabled: Bool {
        UserDefaults.standard.bool(forKey: "enableDriveDirectUploads")
    }

    var canUpload: Bool {
        uploadDestinationPath != nil && isDriveDirectUploadsEnabled
    }

    func enqueueUploads(sources: [WireDriveDirectUploadSource]) async {
        guard let destinationFolderPath = uploadDestinationPath, !sources.isEmpty else { return }

        do {
            try await useCases.enqueueUploads.invoke(
                sources: sources,
                destinationFolderPath: destinationFolderPath
            )
        } catch let error as WireDriveDirectUploadBatchError {
            handle(error)
        } catch {
            WireLogger.wireDrive.error("failed to enqueue drive uploads: \(error)")
        }
    }

    func resolveSource(from item: PhotosPickerItem) async -> WireDriveDirectUploadSource? {
        guard let identifier = item.itemIdentifier else { return nil }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }

        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first(where: { $0.type == .photo || $0.type == .video }) ?? resources.first
        else { return nil }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("drive-upload-picked/\(UUID().uuidString)", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            WireLogger.wireDrive.error("could not create temp directory for picked asset: \(error)")
            return nil
        }

        let destination = directory.appendingPathComponent(resource.originalFilename)

        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true

        return await withCheckedContinuation { continuation in
            PHAssetResourceManager.default().writeData(for: resource, toFile: destination, options: options) { error in
                if let error {
                    WireLogger.wireDrive.error("could not export picked asset for upload: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: WireDriveDirectUploadSource(
                    url: destination,
                    fileName: resource.originalFilename,
                    fileType: item.supportedContentTypes.first,
                    isSecurityScoped: false,
                    localIdentifier: identifier
                ))
            }
        }
    }

    private func handle(_ error: WireDriveDirectUploadBatchError) {
        switch error {
        case let .tooManyFiles(limit):
            alert = AlertModel(
                title: Strings.TooManyFiles.title,
                message: Strings.TooManyFiles.message(limit),
                actionsButtons: []
            )

        case .noFiles:
            break

        case let .stagingFailed(fileName, message):
            WireLogger.wireDrive.error("could not stage \(fileName) for upload: \(message)")
        }
    }
}
