//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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
import UniformTypeIdentifiers
import CoreServices
#if os(iOS)
    import MobileCoreServices
#endif

@objc
public final class UTIHelper: NSObject {

    private class func conformsTo(uti: String, type: UTType) -> Bool {
        guard let utType = UTType(uti) else {
            return false
        }

        return utType.conforms(to: type)
    }

    // MARK: - UTI conformation

    public class func conformsToGifType(uti: String) -> Bool {
        return conformsTo(uti: uti, type: .gif)
    }

    @objc
    public class func conformsToImageType(uti: String) -> Bool {
        guard let utType = UTType(uti) else {
            return false
        }

        return utType.conforms(to: .image)
    }

    @objc
    public class func conformsToVectorType(uti: String) -> Bool {
        return UTType(uti)?.conforms(to: .svg) ?? false
    }

    @objc
    public class func conformsToJsonType(uti: String) -> Bool {
        return UTType(uti)?.conforms(to: .json) ?? false
    }

    // MARK: - MIME conformation

    public class func conformsToGifType(mime: String) -> Bool {
        guard let uti = convertToUti(mime: mime) else { return false }

        return conformsToGifType(uti: uti)
    }

    public class func conformsToAudioType(mime: String) -> Bool {
        guard let uti = convertToUti(mime: mime) else {
            return false
        }
        let audioTypes: [UTType] = [.audio, .mpeg4Audio]
        return audioTypes.contains {
            conformsTo(uti: uti, type: $0)
        }
    }

    public class func conformsToMovieType(mime: String) -> Bool {
        guard let uti = convertToUti(mime: mime) else {
            return false
        }

        let movieTypes: [UTType] = [.movie, .mpeg4Movie, .quickTimeMovie]

        return movieTypes.contains {
            conformsTo(uti: uti, type: $0)
        }
    }

    public class func conformsToVectorType(mime: String) -> Bool {
        guard let uti = convertToUti(mime: mime) else { return false }

        return conformsToVectorType(uti: uti)
    }

    // MARK: - converters

    public class func convertToFileExtension(mime: String) -> String? {
        var utType: UTType? = UTType(mimeType: mime)

        // for uttype not conforming data, e.g pkpass, retry with conformingTo: nil
        if utType == nil || utType?.preferredFilenameExtension == nil {
            utType = UTType(tag: mime, tagClass: .mimeType, conformingTo: nil)
        }

        return utType?.preferredFilenameExtension
    }

    @objc
    public class func convertToUti(mime: String) -> String? {
        guard let utType = UTType(mimeType: mime) else {
            return nil
        }

        return utType.identifier
    }

    public class func convertToMime(fileExtension: String) -> String? {
        guard let utType = UTType(tag: fileExtension, tagClass: .filenameExtension, conformingTo: nil) else {
            return nil
        }

        return mime(from: utType)
    }

    private class func mime(from utType: UTType) -> String? {
        return utType.preferredMIMEType
    }

    @objc
    public class func convertToMime(uti: String) -> String? {
        guard let utType = UTType(uti) else {
            return nil
        }

        return mime(from: utType)
    }

}
