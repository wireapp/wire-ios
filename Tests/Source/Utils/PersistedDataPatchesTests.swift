//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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
import XCTest
@testable import ZMCDataModel

// MARK: - Framework comparison
class FrameworkVersionTests: XCTestCase  {
    
    func testThatCorrectVersionsAreParsed() {
        
        // GIVEN
        let version = FrameworkVersion("13.5.3")
        
        // THEN
        XCTAssertEqual(version?.major, 13)
        XCTAssertEqual(version?.minor, 5)
        XCTAssertEqual(version?.patch, 3)
    }
    
    func testThatCorrectVersionsAreParsedWithZero() {
        
        // GIVEN
        let version = FrameworkVersion("0.5.0")
        
        // THEN
        XCTAssertEqual(version?.major, 0)
        XCTAssertEqual(version?.minor, 5)
        XCTAssertEqual(version?.patch, 0)
    }
    
    func testThatVersionsWithNoPatchAreParsed() {
        
        // GIVEN
        let version = FrameworkVersion("2.5")
        
        // THEN
        XCTAssertEqual(version?.major, 2)
        XCTAssertEqual(version?.minor, 5)
        XCTAssertEqual(version?.patch, 0)
    }
    
    func testThatVersionsWithNoMinorAreParsed() {
        
        // GIVEN
        let version = FrameworkVersion("2")
        
        // THEN
        XCTAssertEqual(version?.major, 2)
        XCTAssertEqual(version?.minor, 0)
        XCTAssertEqual(version?.patch, 0)
    }
    
    func testThatEmptyVersionIsNotParsed() {
        
        // GIVEN
        let version = FrameworkVersion("")
        
        // THEN
        XCTAssertNil(version)
    }
    
    func testThatVersionWithTooManyIsNotParsed() {
        
        // GIVEN
        let version = FrameworkVersion("3.4.5.2")
        
        // THEN
        XCTAssertNil(version)
    }
    
    func testThatVersionWithTextIsNotParsed() {
        
        // GIVEN
        let version = FrameworkVersion("3.4.0-alpha")
        
        // THEN
        XCTAssertNil(version)
    }
    
    func testEquality() {
        XCTAssertEqual(FrameworkVersion("0.2.3"), FrameworkVersion("0.2.3"))
        XCTAssertEqual(FrameworkVersion("0.2.0"), FrameworkVersion("0.2"))
        XCTAssertEqual(FrameworkVersion("0.2"), FrameworkVersion("0.2"))
        XCTAssertNotEqual(FrameworkVersion("1.2.3"), FrameworkVersion("0.2.3"))
        XCTAssertNotEqual(FrameworkVersion("0.2.3"), FrameworkVersion("0.3.3"))
        XCTAssertNotEqual(FrameworkVersion("0.2.3"), FrameworkVersion("0.2.34"))
    }
    
    func testComparison() {
        XCTAssertGreaterThan(FrameworkVersion("3.2.1")!, FrameworkVersion("3.2.0")!)
        XCTAssertLessThan(FrameworkVersion("3.2.0")!, FrameworkVersion("3.2.1")!)
        XCTAssertGreaterThan(FrameworkVersion("3.3.1")!, FrameworkVersion("3.2.15")!)
        XCTAssertLessThan(FrameworkVersion("3.2.15")!, FrameworkVersion("3.3.1")!)
        XCTAssertGreaterThan(FrameworkVersion("4.0.0")!, FrameworkVersion("3.2.1")!)
        XCTAssertLessThan(FrameworkVersion("3.2.1")!, FrameworkVersion("4.0.0")!)
    }
}

// MARK: - Test patches
class PersistedDataPatchesTests: ZMBaseManagedObjectTest {
    
    func testThatItApplyPatchesWhenNoVersion() {
        
        // GIVEN
        var patchApplied = false
        let patch = PersistedDataPatch(version: "9999.32.32") { (moc) in
            XCTAssertEqual(moc, self.syncMOC)
            patchApplied = true
        }
        
        // WHEN
        PersistedDataPatch.applyAll(in: self.syncMOC, patches: [patch])
        
        // THEN
        XCTAssertTrue(patchApplied)
    }
    
    func testThatItApplyPatchesWhenPreviousVersionIsLesser() {
        
        // GIVEN
        var patchApplied = false
        let patch = PersistedDataPatch(version: "10000000.32.32") { (moc) in
            XCTAssertEqual(moc, self.syncMOC)
            patchApplied = true
        }
        // this will bump last patched version to current version, which hopefully is less than 10000000.32.32
        PersistedDataPatch.applyAll(in: self.syncMOC, patches: [])
        
        // WHEN
        PersistedDataPatch.applyAll(in: self.syncMOC, patches: [patch])
        
        // THEN
        XCTAssertTrue(patchApplied)
    }
    
    func testThatItDoesNotApplyPatchesWhenPreviousVersionIsGreater() {
        
        // GIVEN
        var patchApplied = false
        let patch = PersistedDataPatch(version: "0.0.1") { (moc) in
            XCTFail()
            patchApplied = true
        }
        // this will bump last patched version to current version, which is greater than 0.0.1
        PersistedDataPatch.applyAll(in: self.syncMOC, patches: [])
        
        // WHEN
        PersistedDataPatch.applyAll(in: self.syncMOC, patches: [patch])
        
        // THEN
        XCTAssertFalse(patchApplied)
    }
    
    func testThatItMigratesClientsSessionIdentifiers() {

        // GIVEN
        let hardcodedPrekey = "pQABAQUCoQBYIEIir0myj5MJTvs19t585RfVi1dtmL2nJsImTaNXszRwA6EAoQBYIGpa1sQFpCugwFJRfD18d9+TNJN2ZL3H0Mfj/0qZw0ruBPY="
        let selfClient = self.createSelfClient(onMOC: self.syncMOC)
        let newUser = ZMUser.insertNewObject(in: self.syncMOC)
        newUser.remoteIdentifier = UUID.create()
        let newClient = UserClient.insertNewObject(in: self.syncMOC)
        newClient.user = newUser
        newClient.remoteIdentifier = "aabb2d32ab"

        let otrURL = selfClient.keysStore.cryptoboxDirectoryURL
        XCTAssertTrue(selfClient.establishSessionWithClient(newClient, usingPreKey: hardcodedPrekey))
        self.syncMOC.saveOrRollback()
        
        let sessionsURL = otrURL.appendingPathComponent("sessions")
        let oldSession = sessionsURL.appendingPathComponent(newClient.remoteIdentifier!)
        let newSession = sessionsURL.appendingPathComponent(newClient.sessionIdentifier!.rawValue)

        XCTAssertTrue(FileManager.default.fileExists(atPath: newSession.path))
        let previousData = try! Data(contentsOf: newSession)
        
        // move to fake old session
        try! FileManager.default.moveItem(at: newSession, to: oldSession)
        XCTAssertFalse(FileManager.default.fileExists(atPath: newSession.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: oldSession.path))
         
        // WHEN
        PersistedDataPatch.applyAll(in: self.syncMOC, fromVersion: "0.0.0")
        
        // THEN
        let readData = try! Data(contentsOf: newSession)
        XCTAssertEqual(readData, previousData);
        XCTAssertFalse(FileManager.default.fileExists(atPath: oldSession.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: newSession.path))
    }
}
