//
//  File.swift
//  ZMCDataModel
//
//  Created by Marco Conti on 24/08/16.
//  Copyright © 2016 Wire Swiss GmbH. All rights reserved.
//

import Foundation
import XCTest

class ZMAddressBookContactTests : XCTestCase {
    
    func testThatTwoContactsAreTheSame() {
        
        // given
        let name = "Nina"
        let emails = ["nina@example.com", "rocker88@example.com"]
        let phones = ["+155505123"]
        
        // when
        let contact1 = ZMAddressBookContact()
        let contact2 = ZMAddressBookContact()
        for contact in [contact1, contact2] {
            contact.firstName = name
            contact.emailAddresses = emails
            contact.phoneNumbers = phones
        }
        
        // then
        XCTAssertEqual(contact1, contact2)
        XCTAssertEqual(contact1.hash, contact2.hash)
    }
    
    func testThatTwoContactsAreNotTheSameBecauseEmailIsNotSame() {
        
        // given
        let name = "Nina"
        let emails = ["nina@example.com", "rocker88@example.com"]
        let phones = ["+155505123"]
        
        let contact1 = ZMAddressBookContact()
        let contact2 = ZMAddressBookContact()
        for contact in [contact1, contact2] {
            contact.firstName = name
            contact.emailAddresses = emails
            contact.phoneNumbers = phones
        }
        
        // when
        contact2.emailAddresses = []
        
        // then
        XCTAssertNotEqual(contact1, contact2)
        XCTAssertNotEqual(contact1.hash, contact2.hash)

    }
    
    func testThatTwoContactsAreNotTheSameBecausePhoneIsNotSame() {
        
        // given
        let name = "Nina"
        let emails = ["nina@example.com", "rocker88@example.com"]
        let phones = ["+155505123"]
        
        let contact1 = ZMAddressBookContact()
        let contact2 = ZMAddressBookContact()
        for contact in [contact1, contact2] {
            contact.firstName = name
            contact.emailAddresses = emails
            contact.phoneNumbers = phones
        }
        
        // when
        contact2.phoneNumbers = []
        
        // then
        XCTAssertNotEqual(contact1, contact2)
        XCTAssertNotEqual(contact1.hash, contact2.hash)

    }
    
    func testThatTwoContactsAreNotTheSameBecauseNameIsNotSame() {
        
        // given
        let name = "Nina"
        let emails = ["nina@example.com", "rocker88@example.com"]
        let phones = ["+155505123"]
        
        let contact1 = ZMAddressBookContact()
        let contact2 = ZMAddressBookContact()
        for contact in [contact1, contact2] {
            contact.firstName = name
            contact.emailAddresses = emails
            contact.phoneNumbers = phones
        }
        
        // when
        contact2.lastName = "Licci"
        
        // then
        XCTAssertNotEqual(contact1, contact2)
        XCTAssertNotEqual(contact1.hash, contact2.hash)
    }
    
}