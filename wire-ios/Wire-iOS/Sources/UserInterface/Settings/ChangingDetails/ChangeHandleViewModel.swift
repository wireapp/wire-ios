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

import Foundation

enum HandleValidation {
    static var allowedCharacters: CharacterSet = .init(charactersIn: "abcdefghijklmnopqrstuvwxyz_-.")
        .union(.decimalDigits)

    static var allowedLength: CountableClosedRange<Int> {
        2 ... 256
    }
}

/// This struct represents the current state of a handle
/// change operation and performs necessary validation steps of
/// a new handle. The `ChangeHandleViewModel` uses this state
/// to build display and action decisions.
struct HandleChangeState {

    enum ValidationError: Error {
        case tooShort
        case tooLong
        case invalidCharacter
        case sameAsPrevious
    }

    enum HandleAvailability {
        case unknown
        case available
        case taken
    }

    let currentHandle: String?
    private(set) var newHandle: String?
    var availability: HandleAvailability

    var displayHandle: String? {
        newHandle ?? currentHandle
    }

    init(currentHandle: String?, newHandle: String?, availability: HandleAvailability) {
        self.currentHandle = currentHandle
        self.newHandle = newHandle
        self.availability = availability
    }

    /// Validates the passed in handle and updates the state if
    /// no error occurs, otherwise a `ValidationError` will be thrown.
    mutating func update(_ handle: String) throws {
        availability = .unknown
        try validate(handle)
        newHandle = handle
    }

    /// Validation a new handle, if passed in handle
    /// is invalid, an error will be thrown.
    /// This function does not update the `HandleChangeState` itself.
    func validate(_ handle: String) throws {
        let subset = CharacterSet(charactersIn: handle).isSubset(of: HandleValidation.allowedCharacters)
        guard subset, handle.isEqualToUnicodeName else { throw ValidationError.invalidCharacter }
        guard handle.count >= HandleValidation.allowedLength.lowerBound else { throw ValidationError.tooShort }
        guard handle.count <= HandleValidation.allowedLength.upperBound else { throw ValidationError.tooLong }
        guard handle != currentHandle else { throw ValidationError.sameAsPrevious }
    }
}

final class ChangeHandleViewModel {

    struct DisplayModel {
        let displayHandle: String?
        let availability: HandleChangeState.HandleAvailability
        let isSaveEnabled: Bool
        let isDomainHidden: Bool
        let domainText: String
    }

    struct FailureAlert: Equatable {
        let title: String
        let message: String
        let buttonTitle: String
    }

    enum TextChangeAction: Equatable {
        case none
        case checkAvailability(String)
    }

    enum Route: Equatable {
        case none
        case pop
    }

    private(set) var state: HandleChangeState
    private let federationEnabled: Bool
    private let domainString: String?

    var handleToSave: String? {
        state.newHandle
    }

    var displayModel: DisplayModel {
        DisplayModel(
            displayHandle: state.displayHandle,
            availability: state.availability,
            isSaveEnabled: state.availability == .available,
            isDomainHidden: !federationEnabled,
            domainText: federationEnabled ? domainString ?? "" : ""
        )
    }

    var failureAlert: FailureAlert {
        FailureAlert(
            title: L10n.Localizable.Self.Settings.AccountSection.Handle.Change.FailureAlert.title,
            message: L10n.Localizable.Self.Settings.AccountSection.Handle.Change.FailureAlert.message,
            buttonTitle: L10n.Localizable.General.ok
        )
    }

    init(state: HandleChangeState, federationEnabled: Bool, domainString: String?) {
        self.state = state
        self.federationEnabled = federationEnabled
        self.domainString = domainString
    }

    func shouldAllowEditingText(_ text: String) -> Bool {
        do {
            try state.validate(text)
            return true
        } catch HandleChangeState.ValidationError.invalidCharacter {
            return false
        } catch HandleChangeState.ValidationError.tooLong {
            return false
        } catch {
            return true
        }
    }

    func updateText(_ text: String) -> TextChangeAction {
        do {
            try state.update(text)
            return .checkAvailability(text)
        } catch {
            return .none
        }
    }

    func didCheckAvailability(of handle: String, available: Bool) -> Bool {
        guard handle == state.newHandle else { return false }
        state.availability = available ? .available : .taken
        return true
    }

    func didFailToCheckAvailability(of handle: String) -> Bool {
        guard handle == state.newHandle else { return false }

        // If we fail to check we let the user check again by tapping the save button.
        state.availability = .available
        return true
    }

    func didSetHandle(popOnSuccess: Bool) -> Route {
        state.availability = .taken
        return popOnSuccess ? .pop : .none
    }

    func didFailToSetHandleBecauseExisting() {
        state.availability = .taken
    }
}

extension String {

    var isEqualToUnicodeName: Bool {
        applyingTransform(.toUnicodeName, reverse: false) == self
    }
}
