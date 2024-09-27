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
import WireDataModel
import WireDesign

// MARK: - ConversationPingCell

final class ConversationPingCell: ConversationIconBasedCell, ConversationMessageCell {
    typealias AnimationBlock = (_ animationBlock: Any, _ reps: Int) -> Void
    struct Configuration {
        let pingColor: UIColor
        let pingText: NSAttributedString
        var message: ZMConversationMessage?
    }

    var animationBlock: AnimationBlock?
    var isAnimationRunning = false
    var configuration: Configuration?

    func configure(with object: Configuration, animated: Bool) {
        configuration = object
        attributedText = object.pingText
        imageView.setTemplateIcon(.ping, size: 20)
        imageView.tintColor = object.pingColor
        lineView.isHidden = true
    }

    @objc
    func startAnimation() {
        animationBlock = createAnimationBlock()
        animate()
    }

    func stopAnimation() {
        isAnimationRunning = false
        imageView.alpha = 1.0
    }

    func animate() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !self.canAnimationContinue(for: self.configuration?.message) {
                return
            }

            self.isAnimationRunning = true
            self.imageView.alpha = 1.0
            self.animationBlock!(self.animationBlock as Any, 2)
        }
    }

    func createAnimationBlock() -> AnimationBlock {
        let animationBlock: AnimationBlock = { [weak self] otherBlock, reps in
            guard let self else { return }
            imageView.alpha = 1.0

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if !self.canAnimationContinue(for: self.configuration?.message) {
                    return
                }

                self.isAnimationRunning = true

                UIView.animate(easing: .easeOutExpo, duration: 0.7, animations: {
                    self.imageView.transform = CGAffineTransform(scaleX: 1.8, y: 1.8)
                }, completion: { _ in
                    self.imageView.transform = .identity
                })

                UIView.animate(easing: .easeOutQuart, duration: 0.7, animations: {
                    self.imageView.alpha = 0.0
                }, completion: { _ in
                    if reps > 0 {
                        (otherBlock as! AnimationBlock)(self.animationBlock as Any, reps - 1)
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            if !self.canAnimationContinue(for: self.configuration?.message) {
                                return
                            }

                            UIView.animate(easing: .easeOutQuart, duration: 0.55, animations: {
                                self.imageView.alpha = 1.0
                            }, completion: { _ in
                                self.stopAnimation()
                            })
                        }
                    }
                })
            }
        }

        return animationBlock
    }

    func canAnimationContinue(for message: ZMConversationMessage?) -> Bool {
        message?.knockMessageData?.isEqual(configuration?.message?.knockMessageData) ?? false
    }

    func willDisplay() {
        if let conversation = configuration?.message?.conversationLike,
           let lastMessage = conversation.lastMessage,
           let message = configuration?.message, lastMessage.isEqual(message) {
            if message.isKnock {
                startAnimation()
            }
        }
    }
}

// MARK: - ConversationPingCellDescription

final class ConversationPingCellDescription: ConversationMessageCellDescription {
    // MARK: Lifecycle

    init(message: ZMConversationMessage, sender: UserType) {
        let senderText = sender.isSelfUser ? "content.ping.text.you".localized : (sender.name ?? "")
        let pingText = "content.ping.text".localized(pov: sender.pov, args: senderText)

        let text = NSAttributedString(string: pingText, attributes: [
            .font: UIFont.mediumFont,
            .foregroundColor: SemanticColors.Label.textDefault,
        ])

        let pingColor: UIColor = message.isObfuscated ? .accentDimmedFlat : sender.accentColor
        self.configuration = View.Configuration(pingColor: pingColor, pingText: text, message: message)
        self.accessibilityLabel = text.string
        self.actionController = nil
    }

    // MARK: Internal

    typealias View = ConversationPingCell

    let configuration: ConversationPingCell.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var topMargin: Float = 0
    let isFullWidth = true
    let supportsActions = true
    let containsHighlightableContent = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    var showEphemeralTimer: Bool {
        get { false }
        set { /* pings doesn't support the ephemeral timer */ }
    }
}
