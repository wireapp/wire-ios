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


import Foundation
import CoreLocation
@testable import WireDataModel

class ClientMessageTests_Location: BaseZMMessageTests {
 
    func testThatItReturnsLocationMessageDataWhenPresent() {
        // given
        let (latitude, longitude): (Float, Float) = (48.53775, 9.041169)
        let (name, zoom) = ("Tuebingen, Deutschland", Int32(3))
        let message = ZMGenericMessage.message(content: LocationData(latitude: latitude, longitude: longitude, name: name, zoomLevel: zoom).zmLocation())
        
        // when
        let clientMessage = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        clientMessage.add(message.data())
        
        // then
        let locationMessageData = clientMessage.locationMessageData
        XCTAssertNotNil(locationMessageData)
        XCTAssertEqual(locationMessageData?.latitude, latitude)
        XCTAssertEqual(locationMessageData?.longitude, longitude)
        XCTAssertEqual(locationMessageData?.name, name)
        XCTAssertEqual(locationMessageData?.zoomLevel, zoom)
    }
    
    func testThatItDoesNotReturnLocationMessageDataWhenNotPresent() {
        // given
        let clientMessage = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        
        // then
        XCTAssertNil(clientMessage.locationMessageData)
    }
    
}
