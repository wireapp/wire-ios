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

import Photos
import UIKit
import WireSystem
import WireUtilities

// MARK: - PhotoLibraryProtocol

protocol PhotoLibraryProtocol {
    func performChanges(_ changeBlock: @escaping () -> Swift.Void, completionHandler: ((Bool, Error?) -> Swift.Void)?)

    func register(_ observer: PHPhotoLibraryChangeObserver)
    func unregisterChangeObserver(_ observer: PHPhotoLibraryChangeObserver)
}

// MARK: - PHPhotoLibrary + PhotoLibraryProtocol

extension PHPhotoLibrary: PhotoLibraryProtocol {}

// MARK: - AssetChangeRequestProtocol

protocol AssetChangeRequestProtocol: AnyObject {
    @discardableResult
    static func creationRequestForAsset(from image: UIImage) -> Self
    @discardableResult
    static func creationRequestForAssetFromImage(atFileURL fileURL: URL) -> Self?
}

// MARK: - AssetCreationRequestProtocol

protocol AssetCreationRequestProtocol: AnyObject {
    static func forAsset() -> Self
    func addResource(
        with type: PHAssetResourceType,
        data: Data,
        options: PHAssetResourceCreationOptions?
    )
}

// MARK: - PHAssetChangeRequest + AssetChangeRequestProtocol

extension PHAssetChangeRequest: AssetChangeRequestProtocol {}

// MARK: - PHAssetCreationRequest + AssetCreationRequestProtocol

extension PHAssetCreationRequest: AssetCreationRequestProtocol {}

private let log = ZMSLog(tag: "SavableImage")

// MARK: - SavableImage

final class SavableImage: NSObject {
    // MARK: Lifecycle

    init(data: Data, isGIF: Bool) {
        self.isGIF = isGIF
        self.imageData = data
        super.init()
    }

    // MARK: Internal

    enum Source {
        case gif(URL)
        case image(Data)
    }

    typealias ImageSaveCompletion = (Bool) -> Void

    /// Protocols used to inject mock photo services in tests
    var photoLibrary: PhotoLibraryProtocol = PHPhotoLibrary.shared()
    var assetChangeRequestType: AssetChangeRequestProtocol.Type = PHAssetChangeRequest.self
    var assetCreationRequestType: AssetCreationRequestProtocol.Type = PHAssetCreationRequest.self
    var applicationType: ApplicationProtocol.Type = UIApplication.self

    func saveToLibrary(withCompletion completion: ImageSaveCompletion? = .none) {
        guard !writeInProgess else {
            return
        }
        writeInProgess = true
        let source = createSource()

        let cleanup: (Bool) -> Void = { [source] success in
            if case let .gif(url) = source {
                try? FileManager.default.removeItem(at: url)
            }

            completion?(success)
        }

        applicationType.wr_requestOrWarnAboutPhotoLibraryAccess { granted in
            guard granted else {
                return cleanup(false)
            }

            self.photoLibrary.performChanges {
                self.saveImage(using: source)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    self.writeInProgess = false
                    error.map(self.warnAboutError)
                    cleanup(success)
                }
            }
        }
    }

    // MARK: Private

    private var writeInProgess = false
    private let imageData: Data
    private let isGIF: Bool

    private static  func storeGIF(_ data: Data) -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "\(UUID().uuidString).gif")

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            log.error("error writing image data to \(url): \(error)")
        }

        return url
    }

    // SavableImage instances get created when image cells etc are being created and
    // we don't want to write data to disk when we didn't start a save operation, yet.
    private func createSource() -> Source {
        isGIF ? .gif(SavableImage.storeGIF(imageData)) : .image(imageData)
    }

    // Has to be called from inside a `photoLibrary.perform` block
    private func saveImage(using source: Source) {
        switch source {
        case let .gif(url):
            _ = assetChangeRequestType.creationRequestForAssetFromImage(atFileURL: url)
        case let .image(data):
            assetCreationRequestType.forAsset().addResource(
                with: .photo,
                data: data,
                options: PHAssetResourceCreationOptions()
            )
        }
    }

    private func warnAboutError(_ error: Error) {
        log.error("error saving image: \(error)")

        let alert = UIAlertController(
            title: L10n.Localizable.Library.Alert.PermissionWarning.title,
            message: (error as NSError).localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))

        AppDelegate.shared.mainWindow.rootViewController?.present(alert, animated: true)
    }
}
