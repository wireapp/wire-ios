//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

@testable import Wire

class MockConversationMessageCellDescription: ConversationMessageCellDescription {
    typealias View = MockConversationMessageCell

    // MARK: - Life cycle


    // MARK: - topMargin

    var topMargin: CGFloat {
        get { return underlyingTopMargin }
        set(value) { underlyingTopMargin = value }
    }

    var underlyingTopMargin: CGFloat!

    // MARK: - supportsActions

    var supportsActions: Bool {
        get { return underlyingSupportsActions }
        set(value) { underlyingSupportsActions = value }
    }

    var underlyingSupportsActions: Bool!

    // MARK: - showEphemeralTimer

    var showEphemeralTimer: Bool {
        get { return underlyingShowEphemeralTimer }
        set(value) { underlyingShowEphemeralTimer = value }
    }

    var underlyingShowEphemeralTimer: Bool!

    // MARK: - containsHighlightableContent

    var containsHighlightableContent: Bool {
        get { return underlyingContainsHighlightableContent }
        set(value) { underlyingContainsHighlightableContent = value }
    }

    var underlyingContainsHighlightableContent: Bool!

    // MARK: - message

    var message: ZMConversationMessage?

    // MARK: - delegate

    var delegate: ConversationMessageCellDelegate?

    // MARK: - actionController

    var actionController: ConversationMessageActionController?

    // MARK: - configuration

    var configuration: View.Configuration {
        get { return underlyingConfiguration }
        set(value) { underlyingConfiguration = value }
    }

    var underlyingConfiguration: View.Configuration!

    // MARK: - accessibilityIdentifier

    var accessibilityIdentifier: String?

    // MARK: - accessibilityLabel

    var accessibilityLabel: String?


    // MARK: - register

    var registerIn_Invocations: [UITableView] = []
    var registerIn_MockMethod: ((UITableView) -> Void)?

    func register(in tableView: UITableView) {
        registerIn_Invocations.append(tableView)

        guard let mock = registerIn_MockMethod else {
            fatalError("no mock for `registerIn`")
        }

        mock(tableView)
    }

    // MARK: - makeCell

    var makeCellForAt_Invocations: [(tableView: UITableView, indexPath: IndexPath)] = []
    var makeCellForAt_MockMethod: ((UITableView, IndexPath) -> UITableViewCell)?
    var makeCellForAt_MockValue: UITableViewCell?

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        makeCellForAt_Invocations.append((tableView: tableView, indexPath: indexPath))

        if let mock = makeCellForAt_MockMethod {
            return mock(tableView, indexPath)
        } else if let mock = makeCellForAt_MockValue {
            return mock
        } else {
            fatalError("no mock for `makeCellForAt`")
        }
    }

    // MARK: - willDisplayCell

    var willDisplayCell_Invocations: [Void] = []
    var willDisplayCell_MockMethod: (() -> Void)?

    func willDisplayCell() {
        willDisplayCell_Invocations.append(())

        guard let mock = willDisplayCell_MockMethod else {
            fatalError("no mock for `willDisplayCell`")
        }

        mock()
    }

    // MARK: - didEndDisplayingCell

    var didEndDisplayingCell_Invocations: [Void] = []
    var didEndDisplayingCell_MockMethod: (() -> Void)?

    func didEndDisplayingCell() {
        didEndDisplayingCell_Invocations.append(())

        guard let mock = didEndDisplayingCell_MockMethod else {
            fatalError("no mock for `didEndDisplayingCell`")
        }

        mock()
    }

    // MARK: - isConfigurationEqual

    var isConfigurationEqualWith_Invocations: [Any] = []
    var isConfigurationEqualWith_MockMethod: ((Any) -> Bool)?
    var isConfigurationEqualWith_MockValue: Bool?

    func isConfigurationEqual(with other: Any) -> Bool {
        isConfigurationEqualWith_Invocations.append(other)

        if let mock = isConfigurationEqualWith_MockMethod {
            return mock(other)
        } else if let mock = isConfigurationEqualWith_MockValue {
            return mock
        } else {
            fatalError("no mock for `isConfigurationEqualWith`")
        }
    }

}

final class MockConversationMessageCell: UIView, ConversationMessageCell {
    typealias CellDescription = MockConversationMessageCellDescription
    typealias Configuration = Void

    // MARK: - Life cycle


    // MARK: - cellDescription

    var cellDescription: CellDescription?

    // MARK: - isSelected

    var isSelected: Bool {
        get { return underlyingIsSelected }
        set(value) { underlyingIsSelected = value }
    }

    var underlyingIsSelected: Bool!

    // MARK: - selectionView

    var selectionView: UIView?

    // MARK: - selectionRect

    var selectionRect: CGRect {
        get { return underlyingSelectionRect }
        set(value) { underlyingSelectionRect = value }
    }

    var underlyingSelectionRect: CGRect!

    // MARK: - ephemeralTimerTopInset

    var ephemeralTimerTopInset: CGFloat {
        get { return underlyingEphemeralTimerTopInset }
        set(value) { underlyingEphemeralTimerTopInset = value }
    }

    var underlyingEphemeralTimerTopInset: CGFloat!

    // MARK: - message

    var message: ZMConversationMessage?

    // MARK: - delegate

    var delegate: ConversationMessageCellDelegate?

    // MARK: - init

    required init(cellDescription: CellDescription) {
        self.cellDescription = cellDescription
        super.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - configure

    var configureWithAnimated_Invocations: [(object: Configuration, animated: Bool)] = []
    var configureWithAnimated_MockMethod: ((Configuration, Bool) -> Void)?

    func configure(with object: Configuration, animated: Bool) {
        configureWithAnimated_Invocations.append((object: object, animated: animated))

        guard let mock = configureWithAnimated_MockMethod else {
            fatalError("no mock for `configureWithAnimated`")
        }

        mock(object, animated)
    }

    // MARK: - willDisplay

    var willDisplay_Invocations: [Void] = []
    var willDisplay_MockMethod: (() -> Void)?

    func willDisplay() {
        willDisplay_Invocations.append(())

        guard let mock = willDisplay_MockMethod else {
            fatalError("no mock for `willDisplay`")
        }

        mock()
    }

    // MARK: - didEndDisplaying

    var didEndDisplaying_Invocations: [Void] = []
    var didEndDisplaying_MockMethod: (() -> Void)?

    func didEndDisplaying() {
        didEndDisplaying_Invocations.append(())

        guard let mock = didEndDisplaying_MockMethod else {
            fatalError("no mock for `didEndDisplaying`")
        }

        mock()
    }

    // MARK: - prepareForReuse

    var prepareForReuse_Invocations: [Void] = []
    var prepareForReuse_MockMethod: (() -> Void)?

    func prepareForReuse() {
        prepareForReuse_Invocations.append(())

        guard let mock = prepareForReuse_MockMethod else {
            fatalError("no mock for `prepareForReuse`")
        }

        mock()
    }

}

extension ConversationMessageCell where CellDescription == MockConversationMessageCellDescription {

    init() {
        self.init(cellDescription: MockConversationMessageCellDescription())
    }
}
