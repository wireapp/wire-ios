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

#if os(iOS)
    import MobileCoreServices
#endif

/**
 * A list of the tag classes that can be converted from and to Uniform Types.
 */

public enum UTTagClass {
    /// Indicates that the tag is a MIME type.
    case mimeType

    /// Indicates that the tag is a filename extension.
    case fileExtension

    /// The raw value to use with the C UTType API.
    public var rawValue: CFString {
        switch self {
        case .mimeType: return kUTTagClassMIMEType
        case .fileExtension: return kUTTagClassFilenameExtension
        }
    }
}

/**
 * A wrapper around Uniform Type Identifiers.
 */

@available(iOS, deprecated:14.0, message: "use UniformTypeIdentifiers.UTType instead")
public struct UTType: Equatable {

    /// The raw string value to use with the C UTType API.
    public let rawValue: CFString

    // MARK: - Initialization

    /**
     * Creates a wrapper around an existing UTI.
     * - parameter uti: The type identifier to wrap in the object.
     */

    public init(_ uti: CFString) {
        rawValue = uti
    }

    /**
     * Creates a uniform type identifier for the type indicated by the specified tag.
     * - parameter tag: The tag to translate into a uniform type identifier.
     * - parameter tagClass: The class of the `tag` parameter.
     */

    public init?(tag: String, ofClass tagClass: UTTagClass) {
        guard let uti = UTTypeCreatePreferredIdentifierForTag(tagClass.rawValue, tag as CFString, nil)?.takeRetainedValue() else {
            return nil
        }

        self.rawValue = uti
    }

    /**
     * Creates a uniform type identifier for the specified MIME type.
     * - parameter mimeType: The MIME type to translate into a uniform type identifier.
     */

    public init?(mimeType: String) {
        self.init(tag: mimeType, ofClass: .mimeType)
    }

    /**
     * Creates a uniform type identifier for the specified file extension.
     * - parameter mimeType: The file extension to translate into a uniform type identifier.
     */

    public init?(fileExtension: String) {
        self.init(tag: fileExtension, ofClass: .fileExtension)
    }

    // MARK: - Information

    /// Returns the user-readable description of the file format, if available.
    public var localizedDescription: String? {
        return UTTypeCopyDescription(rawValue)?.takeRetainedValue() as String?
    }

    // MARK: - Conversion

    /**
     * Translates  uniform type identifier to a tag in a different type classification method.
     * - parameter tagClass: The class of the tag you want to return.
     * - returns: The preferred tag in the other tag class, or `nil` if there was no translation available.
     */

    public func convert(to tagClass: UTTagClass) -> String? {
        return UTTypeCopyPreferredTagWithClass(rawValue, tagClass.rawValue)?.takeRetainedValue() as String?
    }

    /// Returns the MIME type equivalent to this type identifier, if known.
    public var mimeType: String? {
        return convert(to: .mimeType)
    }

    /// Returns the preferred file extension for this type identifier, if known.
    public var fileExtension: String? {
        return convert(to: .fileExtension)
    }

    // MARK: - Conformance

    /**
     * Returns whether the uniform type identifier conforms to another uniform type identifier.
     * - parameter uti: The uniform type identifier to compare this UTI to.
     * - returns: Returns `true` if this identifier is equal to or conforms to the second type.
     */

    public func conformsTo(_ uti: UTType) -> Bool {
        return UTTypeConformsTo(rawValue, uti.rawValue)
    }

    /**
     * Returns whether the uniform type identifier conforms to another uniform type identifier.
     * - parameter uti: The uniform type identifier to compare this UTI to.
     * - returns: Returns `true` if this identifier is equal to or conforms to the second type.
     */

    public func conformsTo(_ uti: CFString) -> Bool {
        return UTTypeConformsTo(rawValue, uti)
    }

    // MARK: - Equality

    /// Checks if the UTType is equal to another type.
    public static func == (lhs: UTType, rhs: UTType) -> Bool {
        return UTTypeEqual(lhs.rawValue, rhs.rawValue)
    }

    /// Checks if the UTType is equal to another type.
    public static func == (lhs: UTType, rhs: CFString) -> Bool {
        return UTTypeEqual(lhs.rawValue, rhs)
    }

}
