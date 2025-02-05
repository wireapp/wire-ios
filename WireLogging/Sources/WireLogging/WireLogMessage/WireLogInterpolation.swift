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

/// This type's purpose is restricting the automatic conversion of custom types to String, in order to reduce the risk of leaking sensible information.
/// Each custom type which can be logged must define how it should appear in the logs.
/// Query the property `isObfuscationRequired` in order to know, if the value should be obfuscated or not.
/// Use `addText(_:)` and `addAttribute(_:)` to create the content to be logged.
public struct WireLogInterpolation: StringInterpolationProtocol {

    private(set) var content = ""
    private(set) var attributes = [WireLoggerAttribute]()

    public init(literalCapacity: Int, interpolationCount _: Int) {
        content.reserveCapacity(literalCapacity)
    }

    public mutating func appendLiteral(_ literal: StaticString) {
        writeText("\(literal)")
    }

    public mutating func appendInterpolation(_ literal: StaticString) {
        writeText("\(literal)")
    }

    /// Allows for adding additional tags to a log message.
    /// Depending on the logging system the attributes might for example be prepended in brackets or appended separately.
    public mutating func writeAttribute(_ attribute: WireLoggerAttribute) {
        attributes += [attribute]
    }

    /// Adds text to the logged content. The provided value is not obfuscated.
    public mutating func writeText(_ text: String) {
        content += text
    }
}

// TODO: remove this example
//public struct SensibleInformationModel {
//    var content: String
//}
//
//extension WireLogInterpolation {
//    
//    /// Construct the log message content for ``SensibleInformationModel`` values.
//    mutating func appendInterpolation(_ mySensibleInformation: SensibleInformationModel) {
//        let content: String
//        if isObfuscationRequired {
//            let obfuscatedContent = mySensibleInformation. ...
//            content = "SensibleInformationModel( \(obfuscatedContent) )"
//        } else {
//            content = "SensibleInformationModel( \(mySensibleInformation.content) )"
//        }
//        writeText(content)
//
//        let relevantAttributes = ...
//        for relevantAttribute in relevantAttributes {
//            writeAttribute(relevantAttribute)
//        }
//    }
//}
