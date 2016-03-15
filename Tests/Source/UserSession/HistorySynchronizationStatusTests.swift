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


import zmessaging
import XCTest

class HistorySynchronizationStatusTests: MessagingTest {

    func testThatItShouldNotDownloadHistoryWhenItStarts() {
        
        // given
        let sut = ForegroundOnlyHistorySynchronizationStatus(managedObjectContext: self.uiMOC)
        
        // then
        XCTAssertFalse(sut.shouldDownloadFullHistory)
    }

    func testThatItShouldDownloadWhenDidCompleteSync() {
        
        // given
        let sut = ForegroundOnlyHistorySynchronizationStatus(managedObjectContext: self.uiMOC)
        
        // when
        sut.didCompleteSync()
        
        // then
        XCTAssertTrue(sut.shouldDownloadFullHistory)
    }
    
    func testThatItShouldNotDownloadWhenDidCompleteSyncAndThenStartSyncAgain() {
        
        // given
        let sut = ForegroundOnlyHistorySynchronizationStatus(managedObjectContext: self.uiMOC)
        
        // when
        sut.didCompleteSync()
        sut.didStartSync()
        
        // then
        XCTAssertFalse(sut.shouldDownloadFullHistory)
    }
    
    func testThatItShouldNotDownloadWhenDidCompleteSyncAndWillResignActive() {
        
        // given
        let sut = ForegroundOnlyHistorySynchronizationStatus(managedObjectContext: self.uiMOC)
        
        // when
        sut.didCompleteSync()
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationWillResignActiveNotification, object: nil)
        XCTAssertTrue(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertFalse(sut.shouldDownloadFullHistory)
    }

    func testThatItShouldDownloadWhenBecomingActive() {
        
        // given
        let sut = ForegroundOnlyHistorySynchronizationStatus(managedObjectContext: self.uiMOC)
        
        // when
        sut.didCompleteSync()
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidBecomeActiveNotification, object: nil)
        XCTAssertTrue(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertTrue(sut.shouldDownloadFullHistory)
    }
    
    func testThatItShouldNotDownloadAfterBecomingActiveIfItIsNotDoneSyncing() {
        
        // given
        let sut = ForegroundOnlyHistorySynchronizationStatus(managedObjectContext: self.uiMOC)
        
        // when
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidBecomeActiveNotification, object: nil)
        XCTAssertTrue(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertFalse(sut.shouldDownloadFullHistory)
    }
}
