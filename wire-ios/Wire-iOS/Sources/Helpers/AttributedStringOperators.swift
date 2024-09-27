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

import Foundation
import WireDataModel

// MARK: - Operators

// Concats the lhs and rhs and returns a NSAttributedString
infix operator +: AdditionPrecedence

func + (left: NSAttributedString, right: NSAttributedString) -> NSAttributedString {
    let result = NSMutableAttributedString()
    result.append(left)
    result.append(right)
    return NSAttributedString(attributedString: result)
}

func + (left: String, right: NSAttributedString) -> NSAttributedString {
    var range = NSRange(location: 0, length: 0)
    let attributes = right.length > 0 ? right.attributes(at: 0, effectiveRange: &range) : [:]

    let result = NSMutableAttributedString()
    result.append(NSAttributedString(string: left, attributes: attributes))

    result.append(right)
    return NSAttributedString(attributedString: result)
}

func + (left: NSAttributedString, right: String) -> NSAttributedString {
    var range: NSRange? = NSRange(location: 0, length: 0)
    let attributes = left.length > 0 ? left.attributes(at: left.length - 1, effectiveRange: &range!) : [:]

    let result = NSMutableAttributedString()
    result.append(left)
    result.append(NSAttributedString(string: right, attributes: attributes))
    return NSAttributedString(attributedString: result)
}

// Concats the lhs and rhs and assigns the result to the lhs
infix operator +=: AssignmentPrecedence

@discardableResult
func += (left: inout NSMutableAttributedString, right: String) -> NSMutableAttributedString {
    left.append(right.attributedString)
    return left
}

@discardableResult
func += (left: inout NSAttributedString, right: String) -> NSAttributedString {
    left = left + right
    return left
}

@discardableResult
func += (left: inout NSAttributedString, right: NSAttributedString) -> NSAttributedString {
    left = left + right
    return left
}

@discardableResult
func += (left: inout NSAttributedString, right: NSAttributedString?) -> NSAttributedString {
    guard let rhs = right else { return left }
    return left += rhs
}

// Applies the attributes on the rhs to the string on the lhs
infix operator &&: LogicalConjunctionPrecedence

func && (left: String, right: [NSAttributedString.Key: Any]) -> NSAttributedString {
    NSAttributedString(string: left, attributes: right)
}

func && (left: String, right: UIFont) -> NSAttributedString {
    NSAttributedString(string: left, attributes: [.font: right])
}

func && (left: NSAttributedString, right: UIFont?) -> NSAttributedString {
    guard let font = right else { return left }
    let result = NSMutableAttributedString(attributedString: left)
    result.addAttributes([.font: font], range: NSRange(location: 0, length: result.length))
    return NSAttributedString(attributedString: result)
}

func && (left: String, right: UIColor) -> NSAttributedString {
    NSAttributedString(string: left, attributes: [.foregroundColor: right])
}

func && (left: NSAttributedString, right: UIColor) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: left)
    result.addAttributes([.foregroundColor: right], range: NSRange(location: 0, length: result.length))
    return NSAttributedString(attributedString: result)
}

func && (left: NSAttributedString, right: [NSAttributedString.Key: Any]) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: left)
    result.addAttributes(right, range: NSRange(location: 0, length: result.length))
    return NSAttributedString(attributedString: result)
}

// MARK: - Helper Functions

extension String {
    var attributedString: NSAttributedString {
        .init(string: self)
    }
}

// MARK: - ParagraphStyleDescriptor

enum ParagraphStyleDescriptor {
    case lineSpacing(CGFloat)
    case paragraphSpacing(CGFloat)

    // MARK: Internal

    var style: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        switch self {
        case let .lineSpacing(height): style.lineSpacing = height
        case let .paragraphSpacing(spacing): style.paragraphSpacing = spacing
        }
        return style
    }
}

func && (left: NSAttributedString, right: ParagraphStyleDescriptor) -> NSAttributedString {
    let result = NSMutableAttributedString(attributedString: left)
    result.addAttributes([.paragraphStyle: right.style], range: NSRange(location: 0, length: result.length))
    return NSAttributedString(attributedString: result)
}

func && (left: String, right: ParagraphStyleDescriptor) -> NSAttributedString {
    left.attributedString && right
}

// MARK: - PointOfView

// The point of view is important for the localization grammar. In some languages, for example German, the verb has
// to adjust depending on the point of view. @c PointOfView containts the meta-information for the localization system
// in order to understand which localized string should be picked.
// The localization system is trying to pick the adjusted localized string if possible, for example:
// --- In localized .strings file:
// "some.string" = "%@ hat etwas gemacht"; // basic version
// "some.string-you" = "%@ hast etwas gemacht"; // second person version
enum PointOfView: UInt {
    // The localized string does not adjust.
    case none
    // First person: I/We case
    case firstPerson
    // Second person: You case
    case secondPerson
    // Third person: They/He/She/It case
    case thirdPerson

    // MARK: Fileprivate

    fileprivate var suffix: String {
        switch self {
        case .none:
            ""
        case .firstPerson:
            "i"
        case .secondPerson:
            "you"
        case .thirdPerson:
            "they"
        }
    }
}

// MARK: CustomStringConvertible

extension PointOfView: CustomStringConvertible {
    var description: String {
        "POV: \(suffix)"
    }
}

extension String {
    /// Retuns the NSLocalizedString version of self from the InfoPlist table
    var infoPlistLocalized: String {
        localized(table: "InfoPlist")
    }

    /// Returns the NSLocalizedString version of self as found in specified table
    func localized(table tableName: String, bundle: Bundle = Bundle.main) -> String {
        NSLocalizedString(self, tableName: tableName, bundle: bundle, value: "", comment: "")
    }

    /// Used to generate localized strings with plural rules from the stringdict
    func localized(uppercased: Bool = false, pov pointOfView: PointOfView = .none, args: CVarArg...) -> String {
        withVaList(args) {
            let text = NSString(format: self.localized(pov: pointOfView), arguments: $0) as String
            return uppercased ? text.localizedUppercase : text
        }
    }

    func localized(pov pointOfView: PointOfView) -> String {
        let povPath = self + "-" + pointOfView.suffix
        let povVersion = povPath.localized

        if povVersion != povPath, !povVersion.isEmpty {
            return povVersion
        } else {
            return localized
        }
    }
}

extension NSAttributedString {
    // Adds the attribtues to the given substring in self and returns the resulting String
    func addAttributes(
        _ attributes: [NSAttributedString.Key: AnyObject],
        toSubstring substring: String
    ) -> NSAttributedString {
        let mutableSelf = NSMutableAttributedString(attributedString: self)
        mutableSelf.addAttributes(attributes, to: substring)
        return NSAttributedString(attributedString: mutableSelf)
    }

    func setAttributes(
        _ attributes: [NSAttributedString.Key: AnyObject],
        toSubstring substring: String
    ) -> NSAttributedString {
        let substringRange = (string as NSString).range(of: substring)
        guard substringRange.location != NSNotFound else { return self }

        let mutableSelf = NSMutableAttributedString(attributedString: self)
        mutableSelf.setAttributes(attributes, range: substringRange)
        return NSAttributedString(attributedString: mutableSelf)
    }

    func adding(color: UIColor, to substring: String) -> NSAttributedString {
        addAttributes([.foregroundColor: color], toSubstring: substring)
    }

    func adding(font: UIFont, to substring: String) -> NSAttributedString {
        addAttributes([.font: font], toSubstring: substring)
    }
}

extension NSMutableAttributedString {
    func addAttributes(_ attributes: [NSAttributedString.Key: AnyObject], to substring: String) {
        let substringRange = (string as NSString).range(of: substring)

        guard substringRange.location != NSNotFound else { return }

        addAttributes(attributes, range: substringRange)
    }
}
