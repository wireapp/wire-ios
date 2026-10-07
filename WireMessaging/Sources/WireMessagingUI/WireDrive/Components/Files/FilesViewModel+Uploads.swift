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

    private static var pickedMediaDirectoryName: String { "drive-upload-picked" }

    var canUpload: Bool {
        uploadDestinationPath != nil && selfUserRole == .editor && isDriveDirectUploadsEnabled
    }

    func requestPhotosPermissions() async -> Bool {
        let result = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        switch result {
        case .restricted:
            showRestrictedPermissionsAlert()
            return false
        case .denied, .notDetermined:
            showDeniedPermissionsAlert()
            return false
        case .authorized, .limited:
            fallthrough
        @unknown default:
            return true
        }
    }

    func enqueueUploads(sources: [WireDriveDirectUploadSource]) async {
        // Only exports owned by Wire are cleaned up; document-picker originals are never touched.
        defer { removeTemporaryExports(of: sources) }

        guard let destinationFolderPath = uploadDestinationPath, !sources.isEmpty else { return }

        do {
            try await useCases.enqueueUploads.invoke(
                sources: sources,
                destinationFolderPath: destinationFolderPath
            )
        } catch let error as WireDriveDirectUploadBatchError {
            showBatchErrorAlert(error)
        } catch {
            WireLogger.wireDrive.error("failed to enqueue drive uploads: \(error)")
            alert = .unknownError
        }
    }

    func enqueueUploads(mediaItems: [PhotosPickerItem]) async {
        var sources: [WireDriveDirectUploadSource] = []
        var failedImports = 0

        for item in mediaItems {
            if let source = await resolveSource(from: item) {
                sources.append(source)
            } else {
                failedImports += 1
            }
        }

        await enqueueUploads(sources: sources)

        if failedImports > 0, alert == nil {
            showImportFailedAlert()
        }
    }

    private func resolveSource(from item: PhotosPickerItem) async -> WireDriveDirectUploadSource? {
        guard let identifier = item.itemIdentifier else { return nil }

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }

        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first(where: { $0.type == .photo || $0.type == .video }) ?? resources.first
        else { return nil }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(Self.pickedMediaDirectoryName)/\(UUID().uuidString)", isDirectory: true)

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

    private func removeTemporaryExports(of sources: [WireDriveDirectUploadSource]) {
        for source in sources where !source.isSecurityScoped {
            let directory = source.url.deletingLastPathComponent()
            guard directory.deletingLastPathComponent().lastPathComponent == Self.pickedMediaDirectoryName else {
                continue
            }
            try? FileManager.default.removeItem(at: directory)
        }
    }

    // Error handling

    private func showRestrictedPermissionsAlert() {
        alert = AlertModel(
            title: Strings.PermissionWarning.title,
            message: Strings.PermissionWarning.Restrictions.message,
            actionsButtons: []
        )
    }

    private func showDeniedPermissionsAlert() {
        alert = AlertModel(
            title: Strings.PermissionWarning.title,
            message: Strings.PermissionWarning.Denied.message,
            actionsButtons: []
        )
    }

    func showImportFailedAlert() {
        alert = AlertModel(
            title: Strings.ImportFailed.title,
            message: Strings.ImportFailed.message,
            actionsButtons: []
        )
    }

    func showBatchErrorAlert(_ error: WireDriveDirectUploadBatchError) {
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
            alert = AlertModel(
                title: Strings.PrepareFailed.title,
                message: Strings.PrepareFailed.message(fileName),
                actionsButtons: []
            )
        }
    }
}
