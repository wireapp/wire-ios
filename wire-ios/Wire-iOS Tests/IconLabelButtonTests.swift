//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

import WireCommonComponents
import WireTestingPackage
import XCTest

@testable import Wire

final class IconLabelButtonTests: XCTestCase {
    private var button: IconLabelButton!
    private var snapshotHelper: SnapshotHelper!

    override func setUp() {
        super.setUp()
        snapshotHelper = .init()
        button = IconLabelButton.camera()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setNeedsLayout()
        button.layoutIfNeeded()
    }

    override func tearDown() {
        snapshotHelper = nil
        button = nil
        super.tearDown()
    }

    func testIconLabelButton() {
        IconLabelButtonTestCase.Appearance.allCases.forEach {
            verify(appearance: $0)
        }
    }

    func verify(appearance: IconLabelButtonTestCase.Appearance, file: StaticString = #file, line: UInt = #line) {
        button.appearance = appearance.callActionAppearance
        button.isEnabled = appearance.isEnabled
        button.isSelected = appearance.isSelected

        let name = "testIconLabelButton_\(appearance.description)"
        snapshotHelper.verify(matching: button, file: file, testName: name, line: line)
    }
}

struct IconLabelButtonTestCase {
    enum Appearance: CaseIterable {
        typealias AllCases = [Appearance]

        static var allCases: AllCases {
            var cases = AllCases()

            InteractionState.allCases.forEach { interactionState in
                SelectionState.allCases.forEach { selectionState in
                    BlurState.allCases.forEach { blurState in
                        cases += [.dark(blurState, selectionState, interactionState)]
                    }
                    cases += [.light(selectionState, interactionState)]
                }
            }

            return cases
        }

        case dark(BlurState, SelectionState, InteractionState)
        case light(SelectionState, InteractionState)

        var callActionAppearance: CallActionAppearance {
            switch self {
            case let .dark(blurState, _, _): return .dark(blurred: blurState.isBlurred)
            case .light: return .light
            }
        }

        var isSelected: Bool {
            return selectionState.isSelected
        }

        var isEnabled: Bool {
            return interactionState.isEnabled
        }

        var description: String {
            switch self {
            case let .dark(blurState, selectionState, interactionState):
                return "dark_\(blurState.rawValue)_\(selectionState.rawValue)_\(interactionState.rawValue)"
            case let .light(selectionState, interactionState):
                return "light_\(selectionState.rawValue)_\(interactionState.rawValue)"
            }
        }

        private var selectionState: SelectionState {
            switch self {
            case let .dark(_, selectionState, _), let .light(selectionState, _): return selectionState
            }
        }

        private var interactionState: InteractionState {
            switch self {
            case let .dark(_, _, interactionState), let .light(_, interactionState): return interactionState
            }
        }
    }

    enum BlurState: String, CaseIterable {
        case blurred, notBlurred

        var isBlurred: Bool {
            if case .blurred = self { return true }
            return false
        }
    }

    enum SelectionState: String, CaseIterable {
        case selected, unselected

        var isSelected: Bool {
            if case .selected = self { return true }
            return false
        }
    }

    enum InteractionState: String, CaseIterable {
        case enabled, disabled

        var isEnabled: Bool {
            if case .enabled = self { return true }
            return false
        }
    }
}
