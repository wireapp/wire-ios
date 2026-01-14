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

import UIKit
import WireDataModel
import WireMessagingUI
import WireUtilities

protocol ConversationMessageCellDelegate: AnyObject, MessageActionResponder {

    func conversationMessageCell(
        _ contentView: UIView,
        present viewController: UIViewController
    )

    func conversationMessageWantsToOpenUserDetails(
        _ cell: UIView,
        user: UserType,
        sourceView: UIView,
        frame: CGRect
    )

    func conversationMessageWantsToOpenMessageDetails(
        _ cell: UIView,
        for message: ZMConversationMessage,
        preferredDisplayMode: MessageDetailsDisplayMode
    )

    func conversationMessageWantsToOpenGuestOptionsFromView(
        _ cell: UIView,
        sourceView: UIView
    )

    func conversationMessageWantsToOpenParticipantsDetails(
        _ cell: UIView,
        selectedUsers: [UserType],
        sourceView: UIView
    )

    func conversationMessageShouldUpdate()

    /// Notify the delegate that the content size of the message changed.
    func conversationMessageContentDidChangeSize()

}

/// A generic view that displays conversation contents.

protocol ConversationMessageCell: UIView {
    /// The object that contains the configuration of the view.
    associatedtype Configuration

    typealias ZMConversationMessage = WireDataModel.ZMConversationMessage

    /// Whether the cell is selected.
    var isSelected: Bool { get set }

    /// The view to highlight when the cell is selected.
    var selectionView: UIView? { get }

    /// The frame to highlight when the cell is selected.
    var selectionRect: CGRect { get }

    /// The message that is displayed.
    var message: ZMConversationMessage? { get set }

    /// The delegate for the cell.
    var delegate: ConversationMessageCellDelegate? { get set }

    var actionController: ConversationMessageActionController? { get set }

    /// Creates an alert controller for available message actions.
    var menuPresenter: ConversationMessageCellMenuPresenter? { get }

    /// Configures the cell with the specified configuration object.
    /// - parameter object: The view model for the cell.
    /// - parameter animated: True if the view should animate the changes

    func configure(with object: Configuration, animated: Bool)

    /// Called before the cell will be displayed on the screen.
    func willDisplay()

    /// Called after the cell as been moved off screen.
    func didEndDisplaying()

    func prepareForReuse()
}

extension ConversationMessageCell {

    var selectionView: UIView? {
        nil
    }

    var selectionRect: CGRect {
        selectionView?.bounds ?? .zero
    }

    var menuPresenter: ConversationMessageCellMenuPresenter? {
        ConversationMessageCellMenuPresenter(
            contentView: self,
            actionController: actionController,
            conversationMessageCellDelegate: delegate
        )
    }

    func willDisplay() {
        // to be overriden
    }

    func didEndDisplaying() {
        // to be overriden
    }

    func prepareForReuse() {}

}

/// An object that prepares the contents of a conversation cell before
/// it is displayed.
///
/// The role of this object is to provide a `configuration` view model for
/// the view type it declares as the contents of the cell.

protocol ConversationMessageCellDescription: AnyObject {
    /// The view that will be displayed for the cell.
    associatedtype View: ConversationMessageCell, UIView

    typealias ZMConversationMessage = WireDataModel.ZMConversationMessage

    /// A new type of model to replace the cell descriptions eventually.
    /// In order to allow incremental migration to the new approach, the model will be part of the cell description for
    /// now.
    var conversationCellModel: ConversationCellModel? { get }

    /// The top margin is used to configure the spacing between the current and the previous cell.
    var topMargin: CGFloat { get set }

    /// The bottom margin is used to configure the spacing between the current and the following cell.
    var bottomMargin: CGFloat { get set }

    /// Whether the cell supports actions.
    var supportsActions: Bool { get }

    /// Whether the cell contains content that can be highlighted.
    var containsHighlightableContent: Bool { get }

    /// Boolean to check for aligning message content for Bubbles
    var shouldAlignMessageContentForBubbles: Bool { get }

    /// Boolean to check if isCellAlreadyAligned
    var isCellAlreadyAligned: Bool { get }

    /// Boolean to check if isBubbleHasMaximumWidth
    var isBubbleHasMaximumWidth: Bool { get }

    /// The message that is displayed.
    var message: ZMConversationMessage? { get set }

    /// The delegate for the cell.
    var delegate: ConversationMessageCellDelegate? { get set }

    /// The action controller that handles the menu item.
    var actionController: ConversationMessageActionController? { get set }

    /// The configuration object that will be used to populate the cell.
    var configuration: View.Configuration { get }

    /// `True` if the created content view should have this property set to `True`.
    var isAccessibilityElement: Bool { get }

    /// The accessibility identifier of the cell.
    var accessibilityIdentifier: String? { get }

    /// The accessibility label of the cell.
    var accessibilityLabel: String? { get }

    func register(in tableView: UITableView)
    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell
    func willDisplayCell()
    func didEndDisplayingCell()
    func isConfigurationEqual(with other: Any) -> Bool
}

// MARK: - Table View Dequeuing

extension ConversationMessageCellDescription {

    var conversationCellModel: ConversationCellModel? {
        nil
    }

    var supportsActions: Bool {
        false
    }

    var shouldAlignMessageContentForBubbles: Bool {
        false
    }

    var isCellAlreadyAligned: Bool {
        false
    }

    var isBubbleHasMaximumWidth: Bool {
        false
    }

    var isAccessibilityElement: Bool {
        false
    }

    var topMargin: CGFloat {
        get { objc_getAssociatedObject(self, &topMarginKey) as? CGFloat ?? 2 }
        set { objc_setAssociatedObject(self, &topMarginKey, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }

    var bottomMargin: CGFloat {
        get { objc_getAssociatedObject(self, &bottomMarginKey) as? CGFloat ?? 2 }
        set { objc_setAssociatedObject(self, &bottomMarginKey, newValue, .OBJC_ASSOCIATION_ASSIGN) }
    }

    func willDisplayCell() {
        _ = message?.startSelfDestructionIfNeeded()
    }

    func didEndDisplayingCell() {}

    func register(in tableView: UITableView) {
        tableView.register(cell: type(of: self))
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueConversationCell(with: self, for: indexPath)
        cell.cellView.delegate = delegate
        cell.cellView.message = message
        cell.cellView.actionController = actionController
        if let message {
            // sometimes action controller still has background context message
            // so re-set message from main context to avoid crash
            actionController?.message = message
        }
        cell.accessibilityCustomActions = actionController?.makeAccessibilityActions()
        return cell
    }

    func configureCell(_ cell: UITableViewCell, animated: Bool = false) {
        guard let adapterCell = cell as? ConversationMessageCellTableViewAdapter<Self> else { return }
        configureContentView(adapterCell.cellView)
    }

    func configureContentView(_ cellView: any UIView & ConversationMessageCell, animated: Bool = false) {
        guard let cellView = cellView as? View else { return }
        cellView.configure(with: configuration, animated: animated)
        cellView.accessibilityLabel = accessibilityLabel
        cellView.accessibilityIdentifier = accessibilityIdentifier

        if cellView.isVisible {
            _ = message?.startSelfDestructionIfNeeded()
        }
    }

    /// Default implementation of isConfigurationEqual. If the configure is Equatable, see below Conditionally
    /// Conforming for View.Configuration : Equatable
    ///
    /// - Parameter other: other object to compare
    /// - Returns: true if both self and other having same type
    func isConfigurationEqual(with other: Any) -> Bool {
        type(of: self) == type(of: other)
    }

}

private nonisolated(unsafe) var topMarginKey = 0
private nonisolated(unsafe) var bottomMarginKey = 0

extension ConversationMessageCellDescription where View.Configuration: Equatable {

    /// Default implementation of isConfigurationEqual
    ///
    /// - Parameter other: other object to compare
    /// - Returns: true if both self and other having same type, and configures are equal
    func isConfigurationEqual(with other: Any) -> Bool {
        guard let otherConfig = (other as? Self)?.configuration else { return false }

        return configuration == otherConfig
    }
}

/// A type erased box containing a conversation message cell description.

final class AnyConversationMessageCellDescription: NSObject {
    private let cellGenerator: (UITableView, IndexPath) -> UITableViewCell
    private let viewGenerator: (_ frame: CGRect) -> (any UIView & ConversationMessageCell)
    private let registrationBlock: (UITableView) -> Void
    private let configureCell: (UITableViewCell, Bool) -> Void
    private let configureContentView: (any UIView & ConversationMessageCell, Bool) -> Void
    private let baseTypeGetter: () -> AnyClass
    private let instanceGetter: () -> any ConversationMessageCellDescription
    private let isConfigurationEqualBlock: (AnyConversationMessageCellDescription) -> Bool

    private let _conversationCellModel: () -> ConversationCellModel?
    private let _delegate: AnyMutableProperty<ConversationMessageCellDelegate?>
    private let _message: AnyMutableProperty<ZMConversationMessage?>
    private let _actionController: AnyMutableProperty<ConversationMessageActionController?>
    private let _containsHighlightableContent: AnyConstantProperty<Bool>
    private let _supportsActions: () -> Bool
    private let _isAccessibilityElement: AnyConstantProperty<Bool>
    private let _axIdentifier: AnyConstantProperty<String?>
    private let _axLabel: AnyConstantProperty<String?>

    init<T: ConversationMessageCellDescription>(_ description: T) {
        self.registrationBlock = { tableView in
            description.register(in: tableView)
        }

        self.configureCell = { cell, animated in
            description.configureCell(cell, animated: animated)
        }

        self.configureContentView = { contentView, animated in
            description.configureContentView(contentView, animated: animated)
        }

        self.viewGenerator = { frame in
            T.View(frame: frame)
        }

        self.cellGenerator = { tableView, indexPath in
            description.makeCell(for: tableView, at: indexPath)
        }

        self.baseTypeGetter = {
            T.self
        }

        self.instanceGetter = {
            description
        }

        self.isConfigurationEqualBlock = { otherDescription in
            description.isConfigurationEqual(with: otherDescription.instance)
        }

        self._conversationCellModel = { description.conversationCellModel }
        self._delegate = AnyMutableProperty(description, keyPath: \.delegate)
        self._message = AnyMutableProperty(description, keyPath: \.message)
        self._actionController = AnyMutableProperty(description, keyPath: \.actionController)
        self._containsHighlightableContent = AnyConstantProperty(description, keyPath: \.containsHighlightableContent)
        self._supportsActions = { description.supportsActions }
        self._isAccessibilityElement = AnyConstantProperty(description, keyPath: \.isAccessibilityElement)
        self._axIdentifier = AnyConstantProperty(description, keyPath: \.accessibilityIdentifier)
        self._axLabel = AnyConstantProperty(description, keyPath: \.accessibilityLabel)
    }

    var instance: any ConversationMessageCellDescription {
        instanceGetter()
    }

    var baseType: AnyClass {
        baseTypeGetter()
    }

    var conversationCellModel: ConversationCellModel? {
        _conversationCellModel()
    }

    var delegate: ConversationMessageCellDelegate? {
        get { _delegate.getter() }
        set { _delegate.setter(newValue) }
    }

    var message: ZMConversationMessage? {
        get { _message.getter() }
        set { _message.setter(newValue) }
    }

    var actionController: ConversationMessageActionController? {
        get { _actionController.getter() }
        set { _actionController.setter(newValue) }
    }

    var containsHighlightableContent: Bool {
        _containsHighlightableContent.getter()
    }

    var supportsActions: Bool {
        _supportsActions()
    }

    var cellIsAccessibilityElement: Bool {
        _isAccessibilityElement.getter()
    }

    /// The accessibility identifier of the cell.
    var cellAccessibilityIdentifier: String? {
        _axIdentifier.getter()
    }

    /// The accessibility label of the cell.
    var cellAccessibilityLabel: String? {
        _axLabel.getter()
    }

    func configureCell(_ cell: UITableViewCell, animated: Bool = false) {
        configureCell(cell, animated)
    }

    func configureContentView(_ contentView: any UIView & ConversationMessageCell, animated: Bool = false) {
        configureContentView(contentView, animated)
    }

    func register(in tableView: UITableView) {
        registrationBlock(tableView)
    }

    func makeCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        cellGenerator(tableView, indexPath)
    }

    func makeView(frame: CGRect) -> (any UIView & ConversationMessageCell) {
        viewGenerator(frame)
    }

    func isConfigurationEqual(with description: AnyConversationMessageCellDescription) -> Bool {
        isConfigurationEqualBlock(description)
    }

}
