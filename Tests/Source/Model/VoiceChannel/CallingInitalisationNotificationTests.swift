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


import ZMTesting
@testable import ZMCDataModel

class CallingInitialisationNotificationTests : ZMBaseManagedObjectTest {
    
    func testThatItSendTheCorrectNotification() {
        
        func checkThatItNotifiyWithErrorType(errorCode: ZMVoiceChannelErrorCode) -> Bool {
            var isCorrectErrorType = false
            // given
            NSNotificationCenter.defaultCenter().addObserverForName(CallingInitialisationNotificationName, object: nil, queue: nil) { (note: NSNotification) in
                //then
                let callingNotification = note as! CallingInitialisationNotification
                if (callingNotification.errorCode == errorCode) {
                    isCorrectErrorType = true
                }
            }
            // when
            CallingInitialisationNotification.notifyCallingFailedWithErrorCode(errorCode)
            
            // then
            return isCorrectErrorType
        }
        
        //when
        XCTAssertTrue(checkThatItNotifiyWithErrorType(.OngoingGSMCall))
        
        //when
        XCTAssertTrue(checkThatItNotifiyWithErrorType(.SwitchToAudioNotAllowed))
        
        //when
        XCTAssertTrue(checkThatItNotifiyWithErrorType(.SwitchToVideoNotAllowed))
        
        //when
        XCTAssertTrue(checkThatItNotifiyWithErrorType(.VideoCallingNotSupported))
    }
}