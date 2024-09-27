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

protocol BigEndianDataConvertible {
    var asBigEndianData: Data { get }
}

extension GenericMessage {
    func hashOfContent(with timestamp: Date) -> Data? {
        guard let content else {
            return nil
        }
        switch content {
        case let .location(data as BigEndianDataConvertible),
             .text(let data as BigEndianDataConvertible),
             .edited(let data as BigEndianDataConvertible),
             .asset(let data as BigEndianDataConvertible):
            return data.hashWithTimestamp(timestamp: timestamp.timeIntervalSince1970)

        case let .ephemeral(data):
            guard let content = data.content else {
                return nil
            }
            switch content {
            case let .location(data as BigEndianDataConvertible),
                 .text(let data as BigEndianDataConvertible),
                 .asset(let data as BigEndianDataConvertible):
                return data.hashWithTimestamp(timestamp: timestamp.timeIntervalSince1970)
            default:
                return nil
            }

        default:
            return nil
        }
    }
}

extension MessageEdit: BigEndianDataConvertible {
    var asBigEndianData: Data {
        text.asBigEndianData
    }
}

extension WireProtos.Text: BigEndianDataConvertible {
    var asBigEndianData: Data {
        content.asBigEndianData
    }
}

extension Location: BigEndianDataConvertible {
    var asBigEndianData: Data {
        var data = latitude.times1000.asBigEndianData
        data.append(longitude.times1000.asBigEndianData)
        return data
    }
}

extension WireProtos.Asset: BigEndianDataConvertible {
    var asBigEndianData: Data {
        uploaded.assetID.asBigEndianData
    }
}

extension Float {
    fileprivate var times1000: Int {
        Int(roundf(self * 1000.0))
    }
}

extension String: BigEndianDataConvertible {
    var asBigEndianData: Data {
        var data = Data([0xFE, 0xFF]) // Byte order marker
        data.append(self.data(using: .utf16BigEndian)!)
        return data
    }
}

extension Int: BigEndianDataConvertible {
    public var asBigEndianData: Data {
        withUnsafePointer(to: bigEndian) {
            Data(bytes: $0, count: MemoryLayout.size(ofValue: self))
        }
    }
}

extension TimeInterval: BigEndianDataConvertible {
    public var asBigEndianData: Data {
        let long = Int64(self).bigEndian
        return withUnsafePointer(to: long) {
            Data(bytes: $0, count: MemoryLayout.size(ofValue: long))
        }
    }
}

extension BigEndianDataConvertible {
    public func dataWithTimestamp(timestamp: TimeInterval) -> Data {
        var data = asBigEndianData
        data.append(timestamp.asBigEndianData)
        return data
    }

    public func hashWithTimestamp(timestamp: TimeInterval) -> Data {
        dataWithTimestamp(timestamp: timestamp).zmSHA256Digest()
    }
}
