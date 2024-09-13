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

import UIKit
import WireDesign

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

        if let shareablePreviewView {
            shareablePreviewWrapper.addSubview(shareablePreviewView)
        }
        self.shareablePreviewWrapper = shareablePreviewWrapper

        self.shareablePreviewWrapper?.isHidden = !showPreview
    }

    func createViews() {
        view.backgroundColor = SemanticColors.View.backgroundDefault
        containerView.backgroundColor = SemanticColors.View.backgroundDefault
        createShareablePreview()
        tokenField.tokenTitleVerticalAdjustment = 1
        tokenField.textView.placeholderTextAlignment = .natural
        tokenField.textView.accessibilityIdentifier = "textViewSearch"
        tokenField.textView.placeholder = L10n.Localizable.Content.Message.Forward.to
        tokenField.textView.keyboardAppearance = .default
        tokenField.textView.returnKeyType = .done
        tokenField.textView.autocorrectionType = .no
        tokenField.textView.textContainerInset = UIEdgeInsets(top: 9, left: 40, bottom: 11, right: 40)
        tokenField.delegate = self

        clearButton.accessibilityLabel = L10n.Accessibility.SearchView.ClearButton.description
        clearButton.setIcon(.clearInput, size: .tiny, for: .normal)
        clearButton.addTarget(self, action: #selector(onClearButtonPressed), for: .touchUpInside)
        clearButton.setIconColor(SemanticColors.SearchBar.backgroundButton, for: .normal)
        clearButton.isHidden = true

        destinationsTableView.backgroundColor = .clear
        destinationsTableView.register(
            ShareDestinationCell<D>.self,
            forCellReuseIdentifier: ShareDestinationCell<D>.reuseIdentifier
        )
        destinationsTableView.separatorStyle = .none
        destinationsTableView.allowsSelection = true
        destinationsTableView.allowsMultipleSelection = allowsMultipleSelection
        destinationsTableView.keyboardDismissMode = .interactive
        destinationsTableView.delegate = self
        destinationsTableView.dataSource = self

        closeButton.accessibilityLabel = "close"
        closeButton.setIcon(.cross, size: .tiny, for: .normal)
        closeButton.setIconColor(SemanticColors.Icon.foregroundDefault, for: .normal)
        closeButton.addTarget(
            self,
            action: #selector(ShareViewController.onCloseButtonPressed(sender:)),
            for: .touchUpInside
        )

        let sendButtonIconColor = SemanticColors.Icon.foregroundDefaultWhite

        sendButton.accessibilityLabel = "send"
        sendButton.isEnabled = false
        sendButton.setIcon(.send, size: .tiny, for: .normal)
        sendButton.setBackgroundImageColor(UIColor.accent(), for: .normal)
        sendButton.setBackgroundImageColor(UIColor.accentDarken, for: .highlighted)
        sendButton.setBackgroundImageColor(SemanticColors.Button.backgroundSendDisabled, for: .disabled)

        sendButton.setIconColor(sendButtonIconColor, for: .normal)
        sendButton.setIconColor(sendButtonIconColor, for: .highlighted)
        sendButton.setIconColor(sendButtonIconColor, for: .disabled)

        sendButton.circular = true
        sendButton.addTarget(
            self,
            action: #selector(ShareViewController.onSendButtonPressed(sender:)),
            for: .touchUpInside
        )

        if allowsMultipleSelection {
            searchIcon.setTemplateIcon(.search, size: .tiny)
            searchIcon.tintColor = SemanticColors.SearchBar.backgroundButton
        } else {
            clearButton.isHidden = true
            tokenField.isHidden = true
            searchIcon.isHidden = true
            sendButton.isHidden = true
            closeButton.isHidden = true
            bottomSeparatorLine.isHidden = true
        }

        [containerView].forEach(view.addSubview)

        [
            tokenField,
            destinationsTableView,
            closeButton,
            sendButton,
            bottomSeparatorLine,
            topSeparatorView,
            searchIcon,
            clearButton,
        ].forEach(containerView.addSubview)

        if let shareablePreviewWrapper {
            containerView.addSubview(shareablePreviewWrapper)
        }
    }

    func createConstraints() {
        guard let shareablePreviewWrapper,
              let shareablePreviewView else {
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
            sendButton,
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        let shareablePreviewWrapperMargin: CGFloat = 16
        let tokenFieldMargin: CGFloat = 8
        let sendButtonMargin: CGFloat = 12

        let bottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        let shareablePreviewTopConstraint = shareablePreviewWrapper.topAnchor.constraint(
            equalTo: containerView.safeTopAnchor,
            constant: shareablePreviewWrapperMargin
        )
        let tokenFieldShareablePreviewSpacingConstraint = tokenField.topAnchor.constraint(
            equalTo: shareablePreviewWrapper.bottomAnchor,
            constant: shareablePreviewWrapperMargin
        )

        let tokenFieldTopConstraint = tokenField.topAnchor.constraint(
            equalTo: containerView.topAnchor,
            constant: tokenFieldMargin
        )

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
                sendButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -sendButtonMargin),
            ]
        } else {
            tokenFieldHeightConstraint = tokenField.heightAnchor.constraint(equalToConstant: 0)

            allowsMultipleSelectionConstraints = [
                bottomSeparatorLine.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ]
        }

        NSLayoutConstraint.activate(
            [
                containerView.topAnchor.constraint(equalTo: view.topAnchor),
                bottomConstraint,
                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

                shareablePreviewTopConstraint,
                shareablePreviewWrapper.leadingAnchor.constraint(
                    equalTo: containerView.leadingAnchor,
                    constant: shareablePreviewWrapperMargin
                ),
                shareablePreviewWrapper.trailingAnchor.constraint(
                    equalTo: containerView.trailingAnchor,
                    constant: -shareablePreviewWrapperMargin
                ),

                shareablePreviewView.leadingAnchor.constraint(equalTo: shareablePreviewWrapper.leadingAnchor),
                shareablePreviewView.topAnchor.constraint(equalTo: shareablePreviewWrapper.topAnchor),
                shareablePreviewView.trailingAnchor.constraint(equalTo: shareablePreviewWrapper.trailingAnchor),
                shareablePreviewView.bottomAnchor.constraint(equalTo: shareablePreviewWrapper.bottomAnchor),

                tokenFieldShareablePreviewSpacingConstraint,
                tokenFieldTopConstraint,

                tokenField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: tokenFieldMargin),
                tokenField.trailingAnchor.constraint(
                    equalTo: containerView.trailingAnchor,
                    constant: -tokenFieldMargin
                ),
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
                bottomSeparatorLine.heightAnchor.constraint(equalToConstant: .hairline),
            ] +
                allowsMultipleSelectionConstraints
        )

        self.bottomConstraint = bottomConstraint
        self.shareablePreviewTopConstraint = shareablePreviewTopConstraint
        self.tokenFieldShareablePreviewSpacingConstraint = tokenFieldShareablePreviewSpacingConstraint
        self.tokenFieldTopConstraint = tokenFieldTopConstraint

        updateShareablePreviewConstraint()
    }
}
