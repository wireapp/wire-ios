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

public import WireFoundation

public extension AnalyticsEvent {
    enum WireDriveSendFiles {
        /// Sends an event for one file.
        /// - Parameters:
        ///   - containsText: Whether the message that is associated with the files has non-empty text
        ///   - numberOfAttachments: How many files that message contains
        ///   - mixedTypes: Whether the files have at least two different file types
        public static func shareFileNumber(containsText: Bool, numberOfAttachments: Int, mixedTypes: Bool) -> AnalyticsEvent {
            AnalyticsEvent(name: "drive.share_file_number") {
                Segmentation(key: "text", value: containsText)
                Segmentation(key: "num_attachments", value: numberOfAttachments)
                Segmentation(key: "mixed_attachments", value: mixedTypes)
            }
        }
        
        /// Sends an event for one file.
        /// - Parameters:
        ///   - fileExtension: The file extension including the period, like `.pdf` or `.xlsx`
        ///   - fileSize: The size of the file in bytes. The event will not send the exact size but a size category like `100–500KB` or `500MB+`
        public static func shareFile(fileExtension: String, fileSize: UInt64) -> AnalyticsEvent {
            AnalyticsEvent(name: "drive.share_file") {
                Segmentation(key: "attachment_type", value: fileExtension)
                Segmentation(key: "attachment_size", value: fileSizeCategory(for: fileSize))
            }
        }
    }
}

private extension Int {
    var kb: UInt64 {
        UInt64(self) * 1000
    }
    
    var mb: UInt64 {
        self.kb * 1000
    }
}

private func fileSizeCategory(for size: UInt64) -> String {
    switch size {
    case 0..<100.kb:        "0-100KB"
    case 100.kb..<500.kb:   "100–500KB"
    case 500.kb..<1.mb:     "500KB–1MB"
    case 1.mb..<10.mb:      "1–10MB"
    case 10.mb..<50.mb:     "10–50MB"
    case 50.mb..<100.mb:    "50–100MB"
    case 100.mb..<200.mb:   "100–200MB"
    case 200.mb..<350.mb:   "200–350MB"
    case 350.mb..<500.mb:   "350–500MB"
    case 500.mb...:         "500MB+"
    default:                "-"
    }
}
