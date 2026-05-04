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

import XCTest
@testable import Wire

final class ImageMetadataTests: XCTestCase {

    func testImageMetadata() throws {
        // checking if the original image fits the requirements for this test

        let originalImageData = try imageData(resource: "test_image_with_gps_metadata", fileExtension: "jpg")
        let originalImageMetadata = imageMetadata(originalImageData)

        XCTAssert(metadataHasGps(originalImageMetadata), "original image has no GPS metadata")
        XCTAssert(metadataHasSensitiveData(originalImageMetadata), "original image has no sensitive metadata")

        // checking the image data that has been converted to UIImage

        let uiImage = try XCTUnwrap(UIImage(data: originalImageData))

        // converted to jpeg

        let uiImageJpegData = try XCTUnwrap(uiImage.jpegData(compressionQuality: 1.0))
        let jpegConvertedMetadata = imageMetadata(uiImageJpegData)

        XCTAssert(!jpegConvertedMetadata.isEmpty) // converting to jpeg should have kept some metadata
        XCTAssert(!metadataHasGps(jpegConvertedMetadata)) // ... but the GPS metadata should be gone

        // converted to png

        let uiImagePngData = try XCTUnwrap(uiImage.pngData())
        let pngConvertedMetadata = imageMetadata(uiImagePngData)

        XCTAssert(!pngConvertedMetadata.isEmpty) // converting to png should have kept some metadata
        XCTAssert(!metadataHasGps(pngConvertedMetadata)) // ... but the GPS metadata should be gone

        // checking if there is no sensitive metadata after trying to remove the metadata

        let imageDataWithRemovedMetadata = try originalImageData.wr_removingImageMetadata()
        let strippedMetadata = imageMetadata(imageDataWithRemovedMetadata)

        XCTAssert(!metadataHasGps(strippedMetadata), "stripped metadata contains GPS")
        XCTAssert(!metadataHasSensitiveData(strippedMetadata), "stripped metadata contains sensitive data")
    }
}

private func resourcesBundle() -> Bundle {
    Bundle(for: object_getClass(ImageMetadataTests.self)!)
}

private func imageData(resource: String, fileExtension: String) throws -> Data {
    let url = resourcesBundle().url(forResource: resource, withExtension: fileExtension)!
    return try Data(contentsOf: url)
}

private func imageMetadata(_ data: Data) -> [AnyHashable: Any] {
    let imageSource = CGImageSourceCreateWithData((data as! CFMutableData), nil)!
    return CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [AnyHashable: Any] ?? [:]
}

private func metadataTagIsSensitive(_ tag: String) -> Bool {
    sensitiveMetadataTags.contains { $0 == tag }
}

private func metadataHasGps(_ metadata: [AnyHashable: Any]) -> Bool {
    metadata.contains { entry in
        guard let stringKey = entry.key as? String else { return false }
        return stringKey.range(of: "GPS", options: .caseInsensitive) != nil
    }
}

private func metadataHasSensitiveData(_ metadata: [AnyHashable: Any]) -> Bool {
    metadata.contains { entry in
        guard let stringKey = entry.key as? String else { return false }
        if metadataTagIsSensitive(stringKey) {
            return true
        } else {
            // recursively check the metadata which is nested deeper
            return switch entry.value {
            case let dictionaryValue as [AnyHashable: Any]:
                metadataHasSensitiveData(dictionaryValue)
            default:
                false
            }
        }
    }
}

private let sensitiveMetadataTags: [String] = [

    // MARK: - EXIF (Exchangeable Image File Format)

    // Location Data
    "GPSLatitude",
    "GPSLongitude",
    "GPSAltitude",
    "GPSVersionID",
    "GPSDateStamp",
    "GPSTimeStamp",

    // Date and Time of Capture
    "DateTimeOriginal", // Original date and time image was taken
    "CreateDate",       // Date and time of image creation (often same as DateTimeOriginal)
    "ModifyDate",       // Date and time of last modification

    // Camera/Device Information
    "Make",             // Camera manufacturer
    "Model",            // Camera model
    "SerialNumber",     // Device serial number (highly sensitive)
    "Software",         // Software used to process the image
    "LensMake",
    "LensModel",
    "Artist",           // Often contains the photographer's name

    // Thumbnails (embedded, potentially showing unedited content)
    "ThumbnailData",    // Generic term for embedded thumbnail binary data

    // MARK: - IPTC (International Press Telecommunications Council) Photo Metadata

    // Creator/Photographer Information
    "Creator",          // Photographer's name
    "By-line",          // Another field for the photographer's name
    "Contact",          // Contact information for the creator
    "Credit",           // Credit line for the image

    // Copyright Information
    "CopyrightNotice",
    "RightsUsageTerms",

    // Descriptive Information (if too specific or identifying)
    "Keywords",         // User-defined keywords (could contain sensitive terms)
    "Caption/Abstract", // Description of the image
    "Headline",         // Headline for the image
    "City",             // City where photo was taken (if specific to private location)
    "State",            // State/Province where photo was taken
    "Country",          // Country where photo was taken

    // Originating Program
    "OriginatingProgram",

    // MARK: - XMP (Extensible Metadata Platform)

    // History/Edit History
    "xmp:CreatorTool",   // Tool used to create/modify the image
    "xmp:ModifyDate",    // XMP modification date
    "xmp:MetadataDate",  // XMP metadata modification date
    "photoshop:History", // Specific to Photoshop, detailed edit history

    // Document/Instance IDs
    "xmpMM:DocumentID",  // Unique ID for the document
    "xmpMM:InstanceID",  // Unique ID for a specific instance/version

    // AI Generation Prompts (if applicable and sensitive)
    // These often appear in custom namespaces (e.g., 'sd' for Stable Diffusion)
    "Prompt",            // Generic term for embedded prompts
    "NegativePrompt",    // Generic term for embedded negative prompts
    "Parameters"         // Generic term for AI generation parameters
]
