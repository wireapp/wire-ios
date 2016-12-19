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


extension String {

    private enum Transform {
        case toLatin, stripDiacritics, stripCombiningMarks, toUnicodeName

        @available(iOS 9, *)
        var stringTransform: StringTransform {
            switch self {
            case .toLatin: return .toLatin
            case .stripDiacritics: return .stripDiacritics
            case .stripCombiningMarks: return .stripCombiningMarks
            case .toUnicodeName: return .toUnicodeName
            }
        }

        var cfStringTransform: CFString {
            switch self {
            case .toLatin: return kCFStringTransformToLatin
            case .stripDiacritics: return kCFStringTransformStripDiacritics
            case .stripCombiningMarks: return kCFStringTransformStripCombiningMarks
            case .toUnicodeName: return kCFStringTransformToUnicodeName
            }
        }
    }

    private func applying(transform: Transform) -> String? {
        if #available(iOS 9, *) {
            return applyingTransform(transform.stringTransform, reverse: false)
        } else {
            let ref = NSMutableString(string: self) as CFMutableString
            CFStringTransform(ref, nil, transform.cfStringTransform, false)
            return ref as String
        }
    }

    static private var transforms: [Transform] {
        return [
            .toLatin,
            .stripDiacritics,
            .stripCombiningMarks
        ]
    }

    private var normalized: String? {
        return String.transforms.reduce(self) {
            $0?.applying(transform: $1)
        }
    }

    public var containsEmoji: Bool {
        let latinNormalized = normalized
        return latinNormalized != latinNormalized?.applying(transform: .toUnicodeName)
    }

}
