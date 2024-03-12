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

import SwiftUI
import CoreImage.CIFilterBuiltins
import WireCommonComponents

struct QRView: View {
    let qrCode: String
    @State private var image: UIImage?

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
//            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: 210, height: 210)
                }
                        Text("Invite others with a code to this conversation")
                .font(FontSpec.normalRegularFont.swiftUIFont.monospaced())
                .multilineTextAlignment(.center)
//            }
        }
        .onAppear {
            let context = CIContext()
            let logo = UIImage(named: "wire-logo-black")
            guard let ciImage = URL(string: qrCode)?.qrCustomCode(using: .red, logo: logo) else { return }

            let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
            self.image = UIImage(cgImage: cgImage!)
            // generateImage()

        }
    }

    private func generateImage() {
        guard image == nil else { return }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(qrCode.utf8)

        guard
            let outputImage = filter.outputImage,
            let cgImage = context.createCGImage(outputImage, from: outputImage.extent)
        else { return }

        self.image = UIImage(cgImage: cgImage)
    }
}

#Preview {
    QRView(qrCode: "test")
}

// https://github.com/iamsonumalik/CustomQRCodeGenerator/blob/master/CustomQRGenerator.playground/Contents.swift
extension URL {
    func qrCustomCode(using color: UIColor, logo: UIImage? = nil) -> CIImage? {
        let tintedQRImage = qrCode?.tinted(using: color)

        guard let logo = logo?.cgImage else {
            return tintedQRImage
        }

        return tintedQRImage?.addLogo(with: CIImage(cgImage: logo))
    }

    var qrCode: CIImage? {
        let qrFilter = CIFilter.qrCodeGenerator()
        let qrData = Data(absoluteString.utf8)
        qrFilter.setValue(qrData, forKey: "inputMessage")
        let qrTransform = CGAffineTransform(scaleX: 10, y: 10)
        return qrFilter.outputImage?.transformed(by: qrTransform)
    }
}

extension CIImage {
  var transparent: CIImage? {
    return inverted?.blackTransparent
  }

  var inverted: CIImage? {
    guard let invertedColorFilter = CIFilter(name: "CIColorInvert") else { return nil }
    invertedColorFilter.setValue(self, forKey: "inputImage")
    return invertedColorFilter.outputImage
  }

  var blackTransparent: CIImage? {
    guard let blackTransparentCIFilter = CIFilter(name: "CIMaskToAlpha") else { return nil }
    blackTransparentCIFilter.setValue(self, forKey: "inputImage")
    return blackTransparentCIFilter.outputImage
  }

  func tinted(using color: UIColor) -> CIImage? {
    guard
    let transparentQRImage = transparent,
    let filter = CIFilter(name: "CIMultiplyCompositing"),
    let colorFilter = CIFilter(name: "CIConstantColorGenerator") else { return nil }

    let ciColor = CIColor(color: color)
    colorFilter.setValue(ciColor, forKey: kCIInputColorKey)
    let colorImage = colorFilter.outputImage
    filter.setValue(colorImage, forKey: kCIInputImageKey)
    filter.setValue(transparentQRImage, forKey: kCIInputBackgroundImageKey)
    return filter.outputImage!
  }

    func addLogo(with image: CIImage) -> CIImage? {
        guard let combinedFilter = CIFilter(name: "CISourceOverCompositing") else { return nil }
        let centerTransform = CGAffineTransform(translationX: extent.midX - (image.extent.size.width / 2), y: extent.midY - (image.extent.size.height / 2))
        combinedFilter.setValue(image.transformed(by: centerTransform), forKey: "inputImage")
        combinedFilter.setValue(self, forKey: "inputBackgroundImage")
        return combinedFilter.outputImage!
    }
}
