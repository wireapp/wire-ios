//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireLocators
import XCTest

class MeetingFormPage: PageModel {
    override var pageMainElement: XCUIElement {
        titleField
    }

    var titleField: XCUIElement {
        app.textFields[Locators.WireMeetings.MeetingForm.title.rawValue]
    }

    var participantsButton: XCUIElement {
        app.buttons[Locators.WireMeetings.MeetingForm.participants.rawValue]
    }

    var saveButton: XCUIElement {
        app.buttons[Locators.WireMeetings.MeetingForm.save.rawValue]
    }

    var memberSearchField: XCUIElement {
        app.searchFields["Enter a name"]
    }

    var selectMembersButton: XCUIElement {
        app.buttons[Locators.WireMeetings.MeetingForm.membersSelect.rawValue]
    }

    var cancelButton: XCUIElement { app.buttons[Locators.WireMeetings.MeetingForm.cancel.rawValue] }
    var startDateButton: XCUIElement { app.buttons[Locators.WireMeetings.MeetingForm.startDate.rawValue] }
    var startTimeButton: XCUIElement { app.buttons[Locators.WireMeetings.MeetingForm.startTime.rawValue] }
    var endTimeButton: XCUIElement { app.buttons[Locators.WireMeetings.MeetingForm.endTime.rawValue] }
    var repeatButton: XCUIElement { app.buttons[Locators.WireMeetings.MeetingForm.repeatOption.rawValue] }
    var selectedMembersButton: XCUIElement { app.buttons[Locators.WireMeetings.MeetingForm.membersSelected.rawValue] }
    var titleError: XCUIElement { app.staticTexts[Locators.WireMeetings.MeetingForm.titleError.rawValue] }
    var loadingIndicator: XCUIElement { app.progressIndicators[Locators.WireMeetings.MeetingForm.loading.rawValue] }

    func member(_ user: UserInfo) -> XCUIElement {
        app.buttons[Locators.WireMeetings.MeetingForm.memberIdentifier(user.id)]
    }

    @discardableResult
    func cancel() throws -> MeetingsPage {
        XCTAssertTrue(cancelButton.waitAndTap())
        XCTAssertTrue(titleField.waitToDisappear(timeout: 5))
        return try MeetingsPage()
    }

    func assertDateTimes(start: Date, end: Date, locale: String = "en_GB") {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: locale)
        dateFormatter.dateStyle = .short
        XCTAssertEqual(startDateButton.label, dateFormatter.string(from: start))
        // The End date is disabled and hidden from VoiceOver. The End time value includes its date.
        XCTAssertEqual(endTimeButton.value as? String, dateFormatter.string(from: end))
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        XCTAssertEqual(startTimeButton.label, dateFormatter.string(from: start))
        XCTAssertEqual(endTimeButton.label, dateFormatter.string(from: end))
    }

    func selectRepeat(_ title: String) {
        XCTAssertTrue(repeatButton.waitAndTap())
        XCTAssertTrue(app.buttons[title].waitAndTap(), "Repeat option '\(title)' did not appear")
    }

    func assertRepeat(_ title: String) {
        XCTAssertTrue(repeatButton.label.contains(title) || repeatButton.value as? String == title)
    }

    func selectStartDate(_ date: Date) throws {
        XCTAssertTrue(startDateButton.waitAndTap())
        let picker = app.descendants(matching: .any)[Locators.WireMeetings.MeetingForm.datePicker.rawValue].firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        // Use the full calendar date. A bare day number can select an adjacent month.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "EEEE, d MMMM"
        let day = picker.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", formatter.string(from: date)))
            .firstMatch
        if !day.exists {
            XCTAssertTrue(picker.buttons["Next Month"].waitAndTap(), "The next calendar month was not available")
        }
        XCTAssertTrue(day.waitAndTap(), "Calendar date '\(formatter.string(from: date))' did not appear")
        startDateButton.tap()
    }

    func selectTime(start: Bool, hour: Int, minute: Int) {
        let button = start ? startTimeButton : endTimeButton
        XCTAssertTrue(button.waitAndTap())
        let wheels = app.pickerWheels
        XCTAssertTrue(wheels.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(wheels.count, 2, "The time picker must have 24-hour and minute wheels")
        wheels.element(boundBy: 0).adjust(toPickerWheelValue: String(hour))
        wheels.element(boundBy: 1).adjust(toPickerWheelValue: String(format: "%02d", minute))
        button.tap()
    }

    func openParticipants() {
        XCTAssertTrue(participantsButton.waitAndTap())
        XCTAssertTrue(memberSearchField.waitForExistence(timeout: 5))
    }

    func searchMember(_ name: String) {
        memberSearchField.tap()
        let clearButton = memberSearchField.buttons["Clear text"]
        if clearButton.exists { clearButton.tap() }
        memberSearchField.typeText(name)
    }

    func clearMemberSearch() {
        XCTAssertTrue(memberSearchField.buttons["Clear text"].waitAndTap())
    }

    func confirmParticipants() throws {
        let cancelSearch = app.buttons.matching(identifier: "Cancel").allElementsBoundByIndex.first(where: \.isHittable)
        if let cancelSearch, !selectMembersButton.isHittable { cancelSearch.tap() }
        XCTAssertTrue(selectMembersButton.waitAndTap())
        XCTAssertTrue(participantsButton.waitForExistence(timeout: 5))
    }

    @discardableResult
    func replaceTitle(with title: String) -> MeetingFormPage {
        let clearButton = app.descendants(matching: .any)[Locators.WireMeetings.MeetingForm.clearTitle.rawValue]
            .firstMatch
        if clearButton.exists {
            clearButton.tap()
        }
        titleField.tap()
        titleField.typeText(title)
        return self
    }

    @discardableResult
    func addParticipants(_ users: [UserInfo]) throws -> MeetingFormPage {
        openParticipants()
        XCTAssertTrue(selectedMembersButton.waitAndTap(), "Selected members section did not collapse")

        for user in users {
            searchMember(user.name)
            XCTAssertTrue(member(user).waitAndTap(timeout: 10), "Meeting member '\(user.name)' did not appear")
            clearMemberSearch()
        }

        try confirmParticipants()
        return self
    }

    @discardableResult
    func save(timeout: TimeInterval = 30) throws -> MeetingsPage {
        XCTAssertTrue(saveButton.waitAndTap(timeout: 10), "Meeting form save button was not available")
        XCTAssertTrue(titleField.waitToDisappear(timeout: timeout), "Meeting form did not close after save")
        return try MeetingsPage()
    }
}
