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
// along with this program. If not, see <http://www.gnu.org/licenses/>.


import Foundation

public extension NSString {

    /**
     Splits the given string based on a max length without trunkating words.
     Truncates if single words exceed the `maxLength` parameter.
     Max length has to be longer than the length of the longest codepoint in the string.

     - parameter string: The string that should be split
     - parameter maxLength: The maximum length of the data each string should have
     - returns: An array containing the splitted substrings or an empty array in case of
     */

    public func splitInSubstrings(WithMaxLength maxLength: Int) -> [NSString] {
        return (self as String).splitInSubstrings(maxLength).map { $0 as NSString }
    }
}

extension String {

    /**
     Splits the given string based on a max length without trunkating words.
     Truncates if single words exceed the `maxLength` parameter.
     Max length has to be longer than the length of the longest codepoint in the string.

     - parameter string: The string that should be split
     - parameter maxLength: The maximum length of the data each string should have
     - returns: An array containing the splitted substrings or an empty array in case of
     */

    public func splitInSubstrings(maxLength: Int) -> [String] {

        guard lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > maxLength else { return [self] }

        let stringRange = startIndex..<endIndex
        var messages = [String]()
        var previousChunk: String?

        enumerateSubstringsInRange(stringRange, options: [.Localized, .ByWords]) { substring, substringRange, enclosingRange, _ in

            let nextChunk = self[enclosingRange]
            let currentChunk = (previousChunk ?? "") + nextChunk
            let endOfString = enclosingRange.endIndex == self.endIndex
            let nextChunkLength = nextChunk.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)
            let currentChunkLength = currentChunk.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)

            // Easiest case, sum of previous and next does not exceed the maximum
            if currentChunkLength <= maxLength {
                previousChunk = currentChunk

                // Check if we reached the end of the string and add currentChunk if we did
                if endOfString {
                    messages.append(currentChunk)
                }

            } else { // We know the current chunk is to large

                if let previousChunk = previousChunk where !previousChunk.isEmpty {
                    messages.append(previousChunk)
                }

                previousChunk = nextChunk

                if nextChunkLength >= maxLength {
                    messages.appendContentsOf(nextChunk.splitWord(maxLength))
                    previousChunk = nil
                } else if endOfString {
                    if nextChunkLength >= maxLength {
                        messages.appendContentsOf(nextChunk.splitWord(maxLength))
                    } else {
                        messages.append(nextChunk)
                    }
                }
            }
        }

        guard messages.count > 0 else { return self.splitWord(maxLength) }
        return messages
    }
}

// MARK : - Extension to split a string into an array of Strings, each with a maximum length in UTF8 Encoding

public extension String {
    public func splitWord(maxLength: Int) -> [String] {
        var splitted = [String]()
        var currentStart = startIndex

        enumerateSubstringsInRange(startIndex..<endIndex, options: .ByComposedCharacterSequences) { substring, substringRange, enclosingRange, _ in
            let currentSubstring = self[currentStart..<substringRange.endIndex]
            if currentSubstring.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > maxLength {
                let previous = self[currentStart...substringRange.startIndex.predecessor()]
                splitted.append(previous)
                currentStart = substringRange.startIndex
            }

            if substringRange.endIndex == self.endIndex {
                splitted.append(self[currentStart..<self.endIndex])
            }
        }

        return splitted
    }
}
