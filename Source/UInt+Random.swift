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

public extension UInt {
    
    /// Returns a random number within the range [0, upperBound) using the
    /// Data.secureRandomData(length:) method. This implementation is
    /// modulo bias free.
    ///
    public static func secureRandomNumber(upperBound: UInt) -> UInt {
        
        guard upperBound != 0 else { return 0 }
        
        var random: UInt
        
        // To eliminate modulo bias, we must ensure range of possible random
        // numbers is evenly divisible by the upper bound. We do this by
        // trimming the excess remainder off the lower bound (0)
        //
        let min = (UInt.min &- upperBound) % upperBound
        
        repeat {
            // get enough random bytes to fill UInt
            let data = Data.secureRandomData(length: UInt(MemoryLayout<UInt>.size))
            
            // extract the UInt
            random = data.withUnsafeBytes { (pointer: UnsafePointer<UInt>) -> UInt in
                return pointer.pointee
            }
            
        } while random < min
        
        return random % upperBound
    }
}
