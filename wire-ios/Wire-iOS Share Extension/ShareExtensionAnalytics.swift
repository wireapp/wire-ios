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

import MobileCoreServices
import UniformTypeIdentifiers
import WireCommonComponents
import WireShareEngine

enum AttachmentType: Int, CaseIterable {
    static func < (lhs: AttachmentType, rhs: AttachmentType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    case walletPass = 1
    case video
    case image
    case rawFile
    case url
    case fileUrl
}

extension NSItemProvider {
    var hasGifImage: Bool {
        return hasItemConformingToTypeIdentifier(UTType.gif.identifier)
    }

    var hasImage: Bool {
        return hasItemConformingToTypeIdentifier(UTType.image.identifier)
    }

    func hasFile(completion: @escaping (Bool) -> Void) {
        guard !hasImage, !hasVideo, !hasWalletPass else { return completion(false) }
        if hasURL {
            fetchURL { [weak self] url in
                if (url != nil && !url!.isFileURL) || self?.hasData == false {
                    return completion(false)
                }
                completion(true)
            }
        } else {
            completion(hasData)
        }
    }

    private var hasData: Bool {
        return hasItemConformingToTypeIdentifier(UTType.data.identifier)
    }

    var hasURL: Bool {
        return hasItemConformingToTypeIdentifier(UTType.url.identifier) && registeredTypeIdentifiers.count == 1
    }

    var hasFileURL: Bool {
        return hasItemConformingToTypeIdentifier(UTType.url.identifier)
    }

    var hasVideo: Bool {
        guard let uti = registeredTypeIdentifiers.first else { return false }
        return UTType(uti)?.conforms(to: UTType.movie) ?? false
    }

    var hasWalletPass: Bool {
        return hasItemConformingToTypeIdentifier(UnsentFileSendable.passkitUTI)
    }

    var hasRawFile: Bool {
        return hasItemConformingToTypeIdentifier(UTType.content.identifier) && !hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
    }
}
