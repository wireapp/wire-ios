//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

extension ZMGenericMessage {
    
    @objc
    func hashOfContent(with timestamp: Date) -> Data? {
        guard let content = content as? BigEndianDataConvertible else {
            return nil
        }
        
        return content.hashWithTimestamp(timestamp: timestamp.timeIntervalSince1970)
    }
    
}

protocol BigEndianDataConvertible {
    
    var asBigEndianData: Data { get }
    
}

extension ZMMessageEdit: BigEndianDataConvertible {
    
    var asBigEndianData: Data {
        return text?.asBigEndianData ?? Data()
    }
    
}

extension ZMText: BigEndianDataConvertible {
    
    var asBigEndianData: Data {
        return content.asBigEndianData
    }
    
}

extension ZMLocation: BigEndianDataConvertible {
    
    var asBigEndianData: Data {
        var data = latitude.times1000.asBigEndianData
        data.append(longitude.times1000.asBigEndianData)
        return data
    }
    
}

extension ZMAsset: BigEndianDataConvertible {
    
    var asBigEndianData: Data {
        return uploaded?.assetId.asBigEndianData ?? Data()
    }
}

fileprivate extension Float {
    
    var times1000: Int {
        return Int(roundf(self * 1000.0))
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
        return withUnsafePointer(to: self.bigEndian) {
            Data(bytes: $0, count: MemoryLayout.size(ofValue: self))
        }
    }
    
}

extension TimeInterval: BigEndianDataConvertible {
    
    public var asBigEndianData: Data {
        let long = Int64(self).bigEndian
        return withUnsafePointer(to: long) {
            return Data(bytes: $0, count: MemoryLayout.size(ofValue: long))
        }
    }
    
}

extension BigEndianDataConvertible {
    
    public func dataWithTimestamp(timestamp: TimeInterval) -> Data {
        var data = self.asBigEndianData
        data.append(timestamp.asBigEndianData)
        return data
    }
    
    public func hashWithTimestamp(timestamp: TimeInterval) -> Data {
        return dataWithTimestamp(timestamp: timestamp).zmSHA256Digest()
    }
    
}

