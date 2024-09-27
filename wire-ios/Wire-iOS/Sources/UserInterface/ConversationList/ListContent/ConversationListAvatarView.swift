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

// MARK: - RandomGenerator

/// Source of random values.
public protocol RandomGenerator {
    func rand<ContentType>() -> ContentType
}

// MARK: - RandomGeneratorFromData

/// Generates the pseudorandom values from the data given.
/// @param data the source of random values.
final class RandomGeneratorFromData: RandomGenerator {
    // MARK: Lifecycle

    init(data: Data) {
        self.source = data
    }

    // MARK: Public

    public let source: Data

    public func rand<ContentType>() -> ContentType {
        let currentStep = step
        let result = source.withUnsafeBytes { (pointer: UnsafePointer<ContentType>) -> ContentType in
            pointer.advanced(by: currentStep % source.count).pointee
        }
        step += 1

        return result
    }

    // MARK: Private

    private var step = 0
}

extension RandomGeneratorFromData {
    /// Use UUID as plain data to generate random value.
    convenience init(uuid: UUID) {
        self.init(data: (uuid as NSUUID).data()!)
    }
}

extension Array {
    public func shuffled(with generator: RandomGenerator) -> Array {
        var workingCopy = Array(self)
        var result = Array()

        for _ in self {
            let rand: UInt = generator.rand() % UInt(workingCopy.count)

            result.append(workingCopy[Int(rand)])
            workingCopy.remove(at: Int(rand))
        }

        return result
    }
}

extension ZMConversation {
    /// Stable random list of the participants in the conversation. The list would be consistent between platforms
    /// because the conversation UUID is used as the random indexes source.
    var stableRandomParticipants: [ZMUser] {
        let allUsers = activeParticipants.array as! [ZMUser]
        guard let remoteIdentifier else {
            return allUsers
        }

        let rand = RandomGeneratorFromData(uuid: remoteIdentifier)

        return allUsers.shuffled(with: rand)
    }
}

// MARK: - Mode

private enum Mode {
    /// 1-2 participants in conversation:
    /// / AA \
    /// \ AA /
    case one
    /// 3-4 participants in conversation:
    /// / AB \
    /// \ AB /
    case two
    /// 5+ participants in conversation:
    /// / AB \
    /// \ CD /
    case four
}

extension Mode {
    fileprivate init(conversation: ZMConversation) {
        switch (conversation.activeParticipants.count, conversation.conversationType) {
        case (0 ... 2, _), (_, .oneOnOne):
            self = .one
        case (3 ... 5, _):
            self = .two
        default:
            self = .four
        }
    }
}

// MARK: - ConversationListAvatarView

public final class ConversationListAvatarView: UIView {
    // MARK: Lifecycle

    init() {
        super.init(frame: .zero)
        updateCornerRadius()
        backgroundColor = UIColor(white: 0, alpha: 0.16)
        layer.masksToBounds = true
        clippingView.clipsToBounds = true
        addSubview(clippingView)
    }

    @available(*, unavailable)
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var conversation: ZMConversation? = .none {
        didSet {
            guard let conversation else {
                clippingView.subviews.forEach { $0.removeFromSuperview() }
                return
            }

            let stableRandomParticipants = conversation.stableRandomParticipants.filter { !$0.isSelfUser }
            guard !stableRandomParticipants.isEmpty else {
                clippingView.subviews.forEach { $0.removeFromSuperview() }
                return
            }

            accessibilityLabel = "Avatar for \(self.conversation?.displayName)"
            mode = Mode(conversation: conversation)

            var index = 0
            for userImage in userImages() {
                userImage.userSession = ZMUserSession.shared()
                userImage.size = .tiny
                userImage.showInitials = (mode == .one)
                userImage.isCircular = false
                userImage.user = stableRandomParticipants[index]
                index += 1
            }
            setNeedsLayout()
        }
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard bounds != .zero else {
            return
        }

        clippingView.frame = mode == .one ? bounds : bounds.insetBy(dx: 2, dy: 2)

        let size: CGSize
        let inset: CGFloat = 2
        let containerSize = clippingView.bounds.size

        switch mode {
        case .one:
            size = CGSize(width: containerSize.width, height: containerSize.height)

        case .two:
            size = CGSize(width: (containerSize.width - inset) / 2.0, height: containerSize.height)

        case .four:
            size = CGSize(width: (containerSize.width - inset) / 2.0, height: (containerSize.height - inset) / 2.0)
        }

        var xPosition: CGFloat = 0
        var yPosition: CGFloat = 0

        for userImage in userImages() {
            userImage.frame = CGRect(x: xPosition, y: yPosition, width: size.width, height: size.height)
            if xPosition + size.width >= containerSize.width {
                xPosition = 0
                yPosition += size.height + inset
            } else {
                xPosition += size.width + inset
            }
        }

        updateCornerRadius()
    }

    // MARK: Internal

    let clippingView = UIView()
    let imageViewLeftTop = UserImageView()
    lazy var imageViewRightTop = UserImageView()

    lazy var imageViewLeftBottom = UserImageView()

    lazy var imageViewRightBottom = UserImageView()

    func userImages() -> [UserImageView] {
        switch mode {
        case .one:
            [imageViewLeftTop]

        case .two:
            [imageViewLeftTop, imageViewRightTop]

        case .four:
            [imageViewLeftTop, imageViewRightTop, imageViewLeftBottom, imageViewRightBottom]
        }
    }

    // MARK: Private

    private var mode: Mode = .two {
        didSet {
            clippingView.subviews.forEach { $0.removeFromSuperview() }
            userImages().forEach(clippingView.addSubview)

            if mode == .one {
                layer.borderWidth = 0
            } else {
                layer.borderWidth = .hairline
                layer.borderColor = UIColor(white: 1, alpha: 0.24).cgColor
            }
        }
    }

    private func updateCornerRadius() {
        layer.cornerRadius = conversation?.conversationType == .group ? 6 : layer.bounds.width / 2.0
        clippingView.layer.cornerRadius = conversation?.conversationType == .group ? 4 : clippingView.layer.bounds
            .width / 2.0
    }
}
