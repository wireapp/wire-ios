// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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
import Photos
import MobileCoreServices
import CocoaLumberjackSwift

extension ConversationInputBarViewController: CameraKeyboardViewControllerDelegate {
    
    public func cameraKeyboardViewController(controller: CameraKeyboardViewController, didSelectAsset asset: PHAsset) {
        let manager = PHImageManager.defaultManager()
        switch asset.mediaType {
        case .Video:
            controller.showLoadingView = true

            manager.requestAVAssetForVideo(asset, options: .None, resultHandler: { videoAsset, audioMix, info in
                guard let videoAsset = videoAsset else {
                    controller.showLoadingView = false

                    return
                }
                
                var filename: String?
                    
                if let videoURLAsset = videoAsset as? AVURLAsset,
                    let lastPathComponent = videoURLAsset.URL.lastPathComponent {
                    filename = ((lastPathComponent as NSString).stringByDeletingPathExtension as NSString).stringByAppendingPathExtension("mp4")
                }
                
                if filename == .None {
                    filename = "video.mp4"
                }
                
                videoAsset.wr_convertWithCompletion({ URL, videoAsset, error in
                    controller.showLoadingView = false
                    guard let resultURL = URL where error == .None else {
                        return
                    }
                    
                    Analytics.shared()?.tagSentVideoMessage(CMTimeGetSeconds(videoAsset.duration))
                    self.uploadFileAtURL(resultURL)
                    }, filename: filename)
            })
        case .Image:
            let options = PHImageRequestOptions()
            options.deliveryMode = .HighQualityFormat
            manager.requestImageDataForAsset(asset, options: options, resultHandler: { data, uti, orientation, info in
                self.sendController.sendMessageWithImageData(data, completion: .None)
            })
        default:
            // not supported
            break;
        }
    }
    
    @objc public func executeWithCameraRollPermission(closure: ()->()) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .Authorized:
                dispatch_async(dispatch_get_main_queue(), closure)
                
            default:
                // place for .NotDetermined - in this callback status is already determined so should never get here
                break
            }
        }
    }
    
    public func cameraKeyboardViewController(controller: CameraKeyboardViewController, didSelectImageData imageData: NSData) {
        self.sendController.sendMessageWithImageData(imageData, completion: .None)
        let selector = #selector(ConversationInputBarViewController.image(_:didFinishSavingWithError:contextInfo:))
        UIImageWriteToSavedPhotosAlbum(UIImage(data: imageData)!, self, selector, nil)
    }
    
    @objc private func image(image: UIImage?, didFinishSavingWithError error: NSError?, contextInfo: AnyObject) {
        if let error = error {
            DDLogError("didFinishSavingWithError: \(error)")
        }
    }
    
    public func cameraKeyboardViewControllerWantsToOpenFullScreenCamera(controller: CameraKeyboardViewController) {
        self.hideCameraKeyboardViewController {
            self.presentImagePickerSourceType(.Camera, mediaTypes: [kUTTypeMovie as String, kUTTypeImage as String])
        }
    }
    
    public func cameraKeyboardViewControllerWantsToOpenCameraRoll(controller: CameraKeyboardViewController) {
        self.hideCameraKeyboardViewController {
            self.presentImagePickerSourceType(.PhotoLibrary, mediaTypes: [kUTTypeMovie as String, kUTTypeImage as String])
        }
    }
}
