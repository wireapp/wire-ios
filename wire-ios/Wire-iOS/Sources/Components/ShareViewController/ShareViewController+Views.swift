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

import Foundation
import UIKit

extension ShareViewController {

    func createShareablePreview() {
        let shareablePreviewView = shareable.previewView()
        shareablePreviewView?.layer.cornerRadius = 4
        shareablePreviewView?.clipsToBounds = true
        self.shareablePreviewView = shareablePreviewView

        let shareablePreviewWrapper = UIView()
        shareablePreviewWrapper.clipsToBounds = false
        shareablePreviewWrapper.layer.shadowOpacity = 1
        shareablePreviewWrapper.layer.shadowRadius = 8
        shareablePreviewWrapper.layer.shadowOffset = CGSize(width: 0, height: 8)
        shareablePreviewWrapper.layer.shadowColor = UIColor(white: 0, alpha: 0.4).cgColor

        if let shareablePreviewView = shareablePreviewView {
            shareablePreviewWrapper.addSubview(shareablePreviewView)
        }
        self.shareablePreviewWrapper = shareablePreviewWrapper

        self.shareablePreviewWrapper?.isHidden = !showPreview
    }

    func createViews() {
        containerView.backgroundColor = SemanticColors.View.backgroundDefault
        createShareablePreview()
        self.tokenField.tokenTitleVerticalAdjustment = 1
        self.tokenField.textView.placeholderTextAlignment = .natural
        self.tokenField.textView.accessibilityIdentifier = "textViewSearch"
        self.tokenField.textView.placeholder = L10n.Localizable.Content.Message.Forward.to
        self.tokenField.textView.keyboardAppearance = .default
        self.tokenField.textView.returnKeyType = .done
        self.tokenField.textView.autocorrectionType = .no
        self.tokenField.textView.textContainerInset = UIEdgeInsets(top: 9, left: 40, bottom: 11, right: 40)
        self.tokenField.delegate = self

        clearButton.accessibilityLabel = L10n.Accessibility.SearchView.ClearButton.description
        clearButton.setIcon(.clearInput, size: .tiny, for: .normal)
        clearButton.addTarget(self, action: #selector(onClearButtonPressed), for: .touchUpInside)
        clearButton.setIconColor(SemanticColors.SearchBar.backgroundButton, for: .normal)
        clearButton.isHidden = true

        self.destinationsTableView.backgroundColor = .clear
        self.destinationsTableView.register(ShareDestinationCell<D>.self, forCellReuseIdentifier: ShareDestinationCell<D>.reuseIdentifier)
        self.destinationsTableView.separatorStyle = .none
        self.destinationsTableView.allowsSelection = true
        self.destinationsTableView.allowsMultipleSelection = self.allowsMultipleSelection
        self.destinationsTableView.keyboardDismissMode = .interactive
        self.destinationsTableView.delegate = self
        self.destinationsTableView.dataSource = self

        self.closeButton.accessibilityLabel = "close"
        self.closeButton.setIcon(.cross, size: .tiny, for: .normal)
        self.closeButton.setIconColor(SemanticColors.Icon.foregroundDefault, for: .normal)
        self.closeButton.addTarget(self, action: #selector(ShareViewController.onCloseButtonPressed(sender:)), for: .touchUpInside)

        let sendButtonIconColor = SemanticColors.Icon.foregroundDefaultWhite

        self.sendButton.accessibilityLabel = "send"
        self.sendButton.isEnabled = false
        self.sendButton.setIcon(.send, size: .tiny, for: .normal)
        self.sendButton.setBackgroundImageColor(UIColor.accent(), for: .normal)
        self.sendButton.setBackgroundImageColor(UIColor.accentDarken, for: .highlighted)
        self.sendButton.setBackgroundImageColor(SemanticColors.Button.backgroundSendDisabled, for: .disabled)

        self.sendButton.setIconColor(sendButtonIconColor, for: .normal)
        self.sendButton.setIconColor(sendButtonIconColor, for: .highlighted)
        self.sendButton.setIconColor(sendButtonIconColor, for: .disabled)

        self.sendButton.circular = true
        self.sendButton.addTarget(self, action: #selector(ShareViewController.onSendButtonPressed(sender:)), for: .touchUpInside)

        if self.allowsMultipleSelection {
            searchIcon.setTemplateIcon(.search, size: .tiny)
            searchIcon.tintColor = SemanticColors.SearchBar.backgroundButton
        } else {
            self.clearButton.isHidden = true
            self.tokenField.isHidden = true
            self.searchIcon.isHidden = true
            self.sendButton.isHidden = true
            self.closeButton.isHidden = true
            self.bottomSeparatorLine.isHidden = true
        }

        [self.containerView].forEach(self.view.addSubview)

        [self.tokenField, self.destinationsTableView, self.closeButton, self.sendButton, self.bottomSeparatorLine, self.topSeparatorView, self.searchIcon, self.clearButton].forEach(self.containerView.addSubview)

        if let shareablePreviewWrapper = self.shareablePreviewWrapper {
            self.containerView.addSubview(shareablePreviewWrapper)
        }
    }

    func createConstraints() {

        guard let shareablePreviewWrapper = shareablePreviewWrapper,
            let shareablePreviewView = shareablePreviewView else {
                return
        }

        [
            view,
            containerView,
            shareablePreviewWrapper,
            shareablePreviewView,
            tokenField,
            searchIcon,
            clearButton,
            destinationsTableView,
            bottomSeparatorLine,
            topSeparatorView,
            closeButton,
            sendButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let shareablePreviewWrapperMargin: CGFloat = 16
        let tokenFieldMargin: CGFloat = 8
        let sendButtonMargin: CGFloat = 12

        let bottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        let shareablePreviewTopConstraint = shareablePreviewWrapper.topAnchor.constraint(equalTo: containerView.safeTopAnchor, constant: shareablePreviewWrapperMargin)
        let tokenFieldShareablePreviewSpacingConstraint = tokenField.topAnchor.constraint(equalTo: shareablePreviewWrapper.bottomAnchor, constant: shareablePreviewWrapperMargin)

        let tokenFieldTopConstraint = tokenField.topAnchor.constraint(equalTo: containerView.topAnchor, constant: tokenFieldMargin)

        let tokenFieldHeightConstraint: NSLayoutConstraint
        let allowsMultipleSelectionConstraints: [NSLayoutConstraint]
        if allowsMultipleSelection {
            tokenFieldHeightConstraint = tokenField.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)

            allowsMultipleSelectionConstraints = [
                closeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                closeButton.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
                closeButton.widthAnchor.constraint(equalToConstant: 44),
                closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor),

                sendButton.topAnchor.constraint(equalTo: bottomSeparatorLine.bottomAnchor, constant: sendButtonMargin),
                sendButton.widthAnchor.constraint(equalToConstant: 32),
                sendButton.widthAnchor.constraint(equalTo: sendButton.heightAnchor),
                sendButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                sendButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -sendButtonMargin)

            ]
        } else {
            tokenFieldHeightConstraint = tokenField.heightAnchor.constraint(equalToConstant: 0)

            allowsMultipleSelectionConstraints = [
                bottomSeparatorLine.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ]
        }

        NSLayoutConstraint.activate([

            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            bottomConstraint,
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            shareablePreviewTopConstraint,
            shareablePreviewWrapper.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: shareablePreviewWrapperMargin),
            shareablePreviewWrapper.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -shareablePreviewWrapperMargin),

            shareablePreviewView.leadingAnchor.constraint(equalTo: shareablePreviewWrapper.leadingAnchor),
            shareablePreviewView.topAnchor.constraint(equalTo: shareablePreviewWrapper.topAnchor),
            shareablePreviewView.trailingAnchor.constraint(equalTo: shareablePreviewWrapper.trailingAnchor),
            shareablePreviewView.bottomAnchor.constraint(equalTo: shareablePreviewWrapper.bottomAnchor),

            tokenFieldShareablePreviewSpacingConstraint,
            tokenFieldTopConstraint,

            tokenField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: tokenFieldMargin),
            tokenField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -tokenFieldMargin),
            tokenFieldHeightConstraint,

            searchIcon.centerYAnchor.constraint(equalTo: tokenField.centerYAnchor),
            searchIcon.leadingAnchor.constraint(equalTo: tokenField.leadingAnchor, constant: 16),

            clearButton.centerYAnchor.constraint(equalTo: tokenField.centerYAnchor),
            clearButton.leadingAnchor.constraint(equalTo: tokenField.trailingAnchor, constant: -32),

            topSeparatorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topSeparatorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topSeparatorView.topAnchor.constraint(equalTo: destinationsTableView.topAnchor),
            topSeparatorView.heightAnchor.constraint(equalToConstant: .hairline),

            destinationsTableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            destinationsTableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            destinationsTableView.topAnchor.constraint(equalTo: tokenField.bottomAnchor, constant: 8),
            destinationsTableView.bottomAnchor.constraint(equalTo: bottomSeparatorLine.topAnchor),

            bottomSeparatorLine.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bottomSeparatorLine.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomSeparatorLine.heightAnchor.constraint(equalToConstant: .hairline)] + allowsMultipleSelectionConstraints)

        self.bottomConstraint = bottomConstraint
        self.shareablePreviewTopConstraint = shareablePreviewTopConstraint
        self.tokenFieldShareablePreviewSpacingConstraint = tokenFieldShareablePreviewSpacingConstraint
        self.tokenFieldTopConstraint = tokenFieldTopConstraint

        updateShareablePreviewConstraint()
    }

}
