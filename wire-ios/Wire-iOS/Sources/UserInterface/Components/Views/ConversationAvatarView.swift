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

import WireSyncEngine

// MARK: - RandomGenerator

/// Source of random values.
protocol RandomGenerator {
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

    // MARK: Internal

    let source: Data

    func rand<ContentType>() -> ContentType {
        let currentStep = step
        let result = source.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> ContentType in
            pointer.baseAddress!.assumingMemoryBound(to: ContentType.self)
                .advanced(by: currentStep % (source.count - MemoryLayout<ContentType>.size)).pointee
        }
        step += MemoryLayout<ContentType>.size

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
    func shuffled(with generator: RandomGenerator) -> Array {
        var workingCopyIndices = [Int](indices)
        var resultIndices = [Int]()
        forEach { _ in
            let rand: UInt = generator.rand() % UInt(workingCopyIndices.count)

            resultIndices.append(workingCopyIndices[Int(rand)])
            workingCopyIndices.remove(at: Int(rand))
        }

        return resultIndices.map { self[$0] }
    }
}

// MARK: - ZMConversation + StableRandomParticipantsProvider

extension ZMConversation: StableRandomParticipantsProvider {
    /// Stable random list of the participants in the conversation. The list would be consistent between platforms
    /// because the conversation UUID is used as the random indexes source.
    var stableRandomParticipants: [UserType] {
        let allUsers = sortedActiveParticipants
        guard let remoteIdentifier else {
            return allUsers
        }

        let rand = RandomGeneratorFromData(uuid: remoteIdentifier)

        return allUsers.shuffled(with: rand)
    }
}

// MARK: - Mode

enum Mode: Equatable {
    /// 0 participants in conversation:
    /// /    \
    /// \    /
    case none
    /// 1-2 participants in conversation:
    /// / AA \
    /// \ AA /
    case one(serviceUser: Bool)
    /// 2+ participants in conversation:
    /// / AB \
    /// \ CD /
    case four
}

extension Mode {
    /// create a Mode for different cases
    ///
    /// - Parameters:
    ///   - conversationType: when conversationType is nil, it is a incoming connection request
    ///   - users: number of users involved in the conversation
    fileprivate init(conversationType: ZMConversationType? = nil, users: [UserType]) {
        switch (users.count, conversationType) {
        case (0, _):
            self = .none

        case (1, .group?):
            let isServiceUser = users[0].isServiceUser
            self = isServiceUser ? .one(serviceUser: isServiceUser) : .four

        case (1, _):
            self = .one(serviceUser: users[0].isServiceUser)

        default:
            self = .four
        }
    }

    var showInitials: Bool {
        if case .one = self {
            true
        } else {
            false
        }
    }

    var shape: AvatarImageView.Shape {
        switch self {
        case .one(serviceUser: true): .relative
        default: .rectangle
        }
    }
}

typealias ConversationAvatarViewConversation = ConversationLike & StableRandomParticipantsProvider

// MARK: - ConversationAvatarView

final class ConversationAvatarView: UIView {
    // MARK: Lifecycle

    init() {
        super.init(frame: .zero)
        userImageViews.forEach(clippingView.addSubview)
        updateCornerRadius()
        autoresizesSubviews = false
        layer.masksToBounds = true
        clippingView.clipsToBounds = true
        addSubview(clippingView)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    enum Context {
        // one or more users requesting connection to self user
        case connect(users: [UserType])
        // an established conversation or self user has a pending request to other users
        case conversation(conversation: ConversationAvatarViewConversation)
    }

    let clippingView = UIView()
    let imageViewLeftTop: UserImageView = {
        let userImageView = BadgeUserImageView()
        userImageView.initialsFont = .mediumSemiboldFont

        return userImageView
    }()

    lazy var imageViewRightTop = UserImageView()

    lazy var imageViewLeftBottom = UserImageView()

    lazy var imageViewRightBottom = UserImageView()

    let interAvatarInset: CGFloat = 2

    private(set) var mode: Mode = .one(serviceUser: false) {
        didSet {
            clippingView.subviews.forEach { $0.isHidden = true }
            userImages().forEach { $0.isHidden = false }

            if case .one = mode {
                layer.borderWidth = 0
                backgroundColor = .clear
            } else {
                layer.borderWidth = .hairline
                layer.borderColor = UIColor(white: 1, alpha: 0.24).cgColor
                backgroundColor = UIColor(white: 0, alpha: 0.16)
            }

            var index = 0
            for userImage in userImages() {
                userImage.userSession = ZMUserSession.shared()
                userImage.shouldDesaturate = false
                userImage.size = mode == .four ? .tiny : .small
                if index < users.count {
                    userImage.user = users[index]
                } else {
                    userImage.user = nil
                    userImage.container.isOpaque = false
                    userImage.container.backgroundColor = UIColor(white: 0, alpha: 0.24)
                    userImage.avatar = .image(.init())
                }

                userImage.allowsInitials = mode.showInitials
                userImage.shape = mode.shape
                index += 1
            }

            setNeedsLayout()
        }
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: CGFloat.ConversationAvatarView.iconSize, height: CGFloat.ConversationAvatarView.iconSize)
    }

    var containerSize: CGSize {
        clippingView.bounds.size
    }

    func configure(context: Context) {
        switch context {
        case let .connect(users):
            self.users = users
            mode = Mode(users: users)

        case let .conversation(conversation):
            self.conversation = conversation
            mode = Mode(conversationType: conversation.conversationType, users: users)
        }
    }

    func userImages() -> [UserImageView] {
        switch mode {
        case .none:
            []

        case .one:
            [imageViewLeftTop]

        case .four:
            userImageViews
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds != .zero else {
            return
        }

        clippingView.frame = bounds.insetBy(dx: 2, dy: 2)

        switch mode {
        case .none:
            break

        case .one:
            for userImage in userImages() {
                userImage.frame = clippingView.bounds
            }

        case .four:
            layoutMultipleAvatars(with: CGSize(
                width: (containerSize.width - interAvatarInset) / 2.0,
                height: (containerSize.height - interAvatarInset) / 2.0
            ))
        }

        updateCornerRadius()
    }

    // MARK: Private

    private var users: [UserType] = []

    private var conversation: ConversationAvatarViewConversation? = .none {
        didSet {
            guard let conversation else {
                clippingView.subviews.forEach { $0.isHidden = true }
                return
            }

            accessibilityLabel = "Avatar for \(conversation.displayNameWithFallback)"

            let usersOnAvatar: [UserType]
            let stableRandomParticipants = conversation.stableRandomParticipants.filter { !$0.isSelfUser }

            if stableRandomParticipants.isEmpty,
               let connectedUser = conversation.connectedUserType {
                usersOnAvatar = [connectedUser]
            } else {
                usersOnAvatar = stableRandomParticipants
            }

            users = usersOnAvatar
        }
    }

    private var userImageViews: [UserImageView] {
        [imageViewLeftTop, imageViewRightTop, imageViewLeftBottom, imageViewRightBottom]
    }

    private func layoutMultipleAvatars(with size: CGSize) {
        var xPosition: CGFloat = 0
        var yPosition: CGFloat = 0

        for userImage in userImages() {
            userImage.frame = CGRect(x: xPosition, y: yPosition, width: size.width, height: size.height)
            if xPosition + size.width >= containerSize.width {
                xPosition = 0
                yPosition += size.height + interAvatarInset
            } else {
                xPosition += size.width + interAvatarInset
            }
        }
    }

    private func updateCornerRadius() {
        switch mode {
        case let .one(serviceUser: serviceUser):
            layer.cornerRadius = serviceUser ? 0 : layer.bounds.width / 2.0
            clippingView.layer.cornerRadius = serviceUser ? 0 : clippingView.layer.bounds.width / 2.0

        default:
            layer.cornerRadius = 6
            clippingView.layer.cornerRadius = 4
        }
    }
}
