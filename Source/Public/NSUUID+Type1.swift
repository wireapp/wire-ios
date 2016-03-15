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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation

public extension NSUUID {

    /// Returns whether this UUID is of Type 1
    public var isType1UUID : Bool {
        // looking at most significant bits of #7, as defined in: https://tools.ietf.org/html/rfc4122
        var time_high_and_variant : UInt64 = 0
        self.data().getBytes(&time_high_and_variant, range: NSRange.init(location: 4+2, length: 1))
        let type = (time_high_and_variant & 0xf0) >> 4
        return type == 1
    }
    
    /// Read the given number of octets starting at the given location and reverts the octects order
    private func readOctectsReverted(start: UInt, len: UInt) -> UInt64 {
        let data = self.data()
        var result : UInt64 = 0
        for i in Range<UInt>(start: 0, end: len) {
            var readData : UInt32 = 0
            let finalOctetIndex = len-i-1
            data.getBytes(&readData, range: NSRange.init(location: Int(start+i), length: 1))
            let shiftedData = UInt64(readData) << UInt64(8*finalOctetIndex)
            result = result | shiftedData
        }
        return result
    }
    
    /// Returns the type 1 timestamp
    /// - returns: NSDate, or `nil` if the NSUUID is not of Type 1
    public var type1Timestamp : NSDate? {
        /*
        see https://tools.ietf.org/html/rfc4122
        UUID schema
        --------------------------------------------------------------------------------------------------------------------------
        .... | version / time_high 1 | time_high 2 | time_mid 1 | time_mid 2 | time_low 1 | time_low 2 | time_low 3 | time_low 4 |
        Octet:--7(4-7)-----7(0-3)-----------6------------5------------4------------3------------2------------1-------------0------
        */

        if !self.isType1UUID {
            return nil
        }
        
        // extracting fields
        let time_low = self.readOctectsReverted(0, len: 4)
        let time_mid = self.readOctectsReverted(4, len: 2)
        let time_high_and_variant = self.readOctectsReverted(4+2, len: 2)
        let time_high = (time_high_and_variant & 0x0fff)
        
        
        // calculting time
        let time : UInt64 = time_low |
            time_mid << 32 |
            time_high << 48
        let referenceDate : UInt64 = 0x01b21dd213814000 // 15 Oct 1582, 00:00:00
        let nanoseconds100SinceUnixTimestamp = time - referenceDate
        let nanoseconds100ToSeconds = Double(10000000)
        let unixTimestamp = Double(nanoseconds100SinceUnixTimestamp) / nanoseconds100ToSeconds
        return NSDate(timeIntervalSince1970: unixTimestamp)
    }

    /// Returns the comparison result for this NSUUID of type 1 and another NSUUID of type 1
    /// - Requires: will assert if any UUID is not of type 1
    public func compareWithType1(uuid: NSUUID) -> NSComparisonResult {
        assert(self.isType1UUID && uuid.isType1UUID)
        return self.type1Timestamp!.compare(uuid.type1Timestamp!)
    }

}