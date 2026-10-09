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
        app.searchFields[Self.localized("wireMeetings.schedule.members.search.field.placeholder")]
    }

    var noMemberSearchResults: XCUIElement {
        app.staticTexts[Locators.WireMeetings.MeetingForm.membersEmptySearch.rawValue]
    }

    var schedulingErrorAlert: XCUIElement {
        app.alerts[Self.localized("meetings.scheduleModal.error.createFailedTitle")]
    }

    var selectMembersButton: XCUIElement {
        app.buttons[Locators.WireMeetings.MeetingForm.membersSelect.rawValue]
    }

    var cancelButton: XCUIElement {
        app.buttons[Locators.WireMeetings.MeetingForm.cancel.rawValue]
    }

    var startDateButton: XCUIElement {
        app.buttons[Locators.WireMeetings.MeetingForm.startDate.rawValue]
    }

    var startTimeButton: XCUIElement {
        app.buttons[Locators.WireMeetings.MeetingForm.startTime.rawValue]
    }

    var endTimeButton: XCUIElement {
        app.buttons[Locators.WireMeetings.MeetingForm.endTime.rawValue]
    }

    var repeatButton: XCUIElement {
        app.buttons[Locators.WireMeetings.MeetingForm.repeatOption.rawValue]
    }

    var selectedMembersButton: XCUIElement {
        app.buttons.matching(NSPredicate(
            format: "identifier BEGINSWITH %@",
            Locators.WireMeetings.MeetingForm.membersSelected.rawValue + "."
        )).firstMatch
    }

    var titleError: XCUIElement {
        app.staticTexts[Locators.WireMeetings.MeetingForm.titleError.rawValue]
    }

    var loadingIndicator: XCUIElement {
        app.activityIndicators[Locators.WireMeetings.MeetingForm.loading.rawValue]
    }

    static func localized(_ key: String) -> String {
        // Use the app's English strings resource. UI tests launch with -AppleLanguages (en).
        Bundle(for: MeetingFormPage.self).localizedString(forKey: key, value: nil, table: nil)
    }

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

    func dateTimes(locale: String = "en_GB") throws -> (start: Date, end: Date) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: locale)

        func dateTime(dateLabel: String, timeLabel: String) throws -> Date {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            let day = try XCTUnwrap(formatter.date(from: dateLabel), "Invalid meeting date: '\(dateLabel)'")
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            let time = try XCTUnwrap(formatter.date(from: timeLabel), "Invalid meeting time: '\(timeLabel)'")
            let components = formatter.calendar.dateComponents([.hour, .minute], from: time)
            return try XCTUnwrap(formatter.calendar.date(
                bySettingHour: try XCTUnwrap(components.hour),
                minute: try XCTUnwrap(components.minute),
                second: 0,
                of: day
            ))
        }

        return try (
            dateTime(dateLabel: startDateButton.label, timeLabel: startTimeButton.label),
            dateTime(dateLabel: XCTUnwrap(endTimeButton.value as? String), timeLabel: endTimeButton.label)
        )
    }

    func selectRepeat(_ title: String) {
        XCTAssertTrue(repeatButton.waitAndTap())
        XCTAssertTrue(app.buttons[title].waitAndTap(), "Repeat option '\(title)' did not appear")
    }

    func assertRepeat(_ title: String) {
        XCTAssertTrue(repeatButton.label.contains(title) || repeatButton.value as? String == title)
    }

    func selectStartDate(_ date: Date) throws {
        guard startDateButton.waitAndTap() else {
            throw RuntimeError("Start date button was not available")
        }
        let picker = app.descendants(matching: .any)[Locators.WireMeetings.MeetingForm.datePicker.rawValue].firstMatch
        guard picker.waitForExistence(timeout: 5) else {
            throw RuntimeError("Calendar did not appear")
        }
        // Use the full calendar date. A bare day number can select an adjacent month.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "MMMM yyyy"
        let targetMonth = formatter.string(from: date)
        let month = picker.buttons["Month"]
        guard month.waitForExistence(timeout: 5), let visibleMonth = month.value as? String else {
            throw RuntimeError("Calendar month was not available")
        }
        if visibleMonth != targetMonth {
            guard picker.buttons["DatePicker.NextMonth"].waitAndTap() else {
                throw RuntimeError("The next calendar month was not available")
            }
        }
        let expectedMonth = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", targetMonth), object: month
        )
        guard XCTWaiter().wait(for: [expectedMonth], timeout: 5) == .completed else {
            throw RuntimeError("Calendar month '\(targetMonth)' did not appear")
        }
        formatter.dateFormat = "EEEE d MMMM"
        let day = picker.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", formatter.string(from: date)))
            .firstMatch
        guard day.waitAndTap() else {
            throw RuntimeError("Calendar date '\(formatter.string(from: date))' did not appear")
        }
        guard startDateButton.waitAndTap() else {
            throw RuntimeError("Calendar did not close")
        }
    }

    func selectTime(start: Bool, hour: Int, minute: Int) throws {
        let button = start ? startTimeButton : endTimeButton
        guard button.waitAndTap() else { throw RuntimeError("Time button was not available") }
        let wheels = app.pickerWheels
        guard wheels.firstMatch.waitForExistence(timeout: 5), wheels.count == 2 else {
            throw RuntimeError("The time picker must have 24-hour and minute wheels")
        }
        wheels.element(boundBy: 0).adjust(toPickerWheelValue: String(format: "%02d", hour))
        wheels.element(boundBy: 1).adjust(toPickerWheelValue: String(format: "%02d", minute))
        guard button.waitAndTap() else { throw RuntimeError("Time picker did not close") }
    }

    func openParticipants() throws {
        guard participantsButton.waitAndTap(), memberSearchField.waitForExistence(timeout: 5) else {
            throw RuntimeError("Participant picker did not appear")
        }
    }

    func searchMember(_ name: String) {
        memberSearchField.tap()
        let clearButton = memberSearchField.buttons["Clear text"]
        if clearButton.exists { clearButton.tap() }
        memberSearchField.typeText(name)
    }

    func clearMemberSearch() throws {
        guard memberSearchField.buttons["Clear text"].waitAndTap() else {
            throw RuntimeError("Participant search could not be cleared")
        }
    }

    func selectMember(_ user: UserInfo) throws {
        searchMember(user.name)
        guard selectedMembersButton.waitForExistence(timeout: 5) else {
            throw RuntimeError("Selected members section did not appear")
        }
        if selectedMembersButton.identifier == Locators.WireMeetings.MeetingForm.selectedMembersIdentifier(
            isExpanded: true
        ) {
            guard selectedMembersButton.waitAndTap() else {
                throw RuntimeError("Selected members section was not tappable")
            }
        }
        let collapsed = XCTNSPredicateExpectation(
            predicate: NSPredicate(
                format: "exists == true AND identifier == %@",
                Locators.WireMeetings.MeetingForm.selectedMembersIdentifier(isExpanded: false)
            ),
            object: selectedMembersButton
        )
        guard XCTWaiter().wait(for: [collapsed], timeout: 5) == .completed else {
            throw RuntimeError("Selected members section did not collapse")
        }
        guard member(user).waitAndTap(timeout: 10) else {
            throw RuntimeError("Meeting member '\(user.name)' was not tappable")
        }
    }

    func confirmParticipants() throws {
        let cancelSearch = app.buttons
            .matching(identifier: Locators.WireMeetings.MeetingForm.membersCancelSearch.rawValue)
            .allElementsBoundByIndex.first(where: \.isHittable)
        if let cancelSearch, !selectMembersButton.isHittable {
            cancelSearch.tap()
        }
        guard selectMembersButton.waitAndTap(), participantsButton.waitForExistence(timeout: 5) else {
            throw RuntimeError("Participant selection was not confirmed")
        }
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
        try openParticipants()

        for user in users {
            try selectMember(user)
            try clearMemberSearch()
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
