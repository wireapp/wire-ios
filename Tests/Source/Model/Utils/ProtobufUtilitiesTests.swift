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


import XCTest

class ProtobufUtilitiesTests: XCTestCase {
    
    func testThatItSetsAndReadsTheLoudness() {
        
        // given
        let loudness : [Float] = [0.8, 0.3, 1.0, 0.0, 0.001]
        let sut = ZMAssetOriginal.original(withSize: 200, mimeType: "audio/m4a", name: "foo.m4a", audioDurationInMillis: 1000, normalizedLoudness: loudness)

        // when
        let extractedLoudness = sut.audio.normalizedLoudness
        
        // then
        XCTAssertTrue(sut.audio.hasNormalizedLoudness())
        XCTAssertEqual(extractedLoudness.length, loudness.count)
        XCTAssertEqual(loudness.map { Float(UInt8(roundf($0*255)))/255.0 } , sut.normalizedLoudnessLevels)
    }
    
    func testThatItDoesNotReturnTheLoudnessIfEmpty() {
        
        // given
        let sut = ZMAssetOriginal.original(withSize: 234, mimeType: "foo/bar", name: "boo.bar")
        
        // then
        XCTAssertEqual(sut.normalizedLoudnessLevels, [])
        
    }
}
