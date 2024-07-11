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

import AVFoundation
import SwiftUI

class QRScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {

    @Binding var scannedCode: String?
    @Binding var latestCode: String?

    init(scannedCode: Binding<String?>, latestCode: Binding<String?>) {
        _scannedCode = scannedCode
        _latestCode = latestCode
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            guard metadataObject.type == .qr else { return }

            if let stringValue = metadataObject.stringValue {
                latestCode = stringValue
            }
        }
    }
}
