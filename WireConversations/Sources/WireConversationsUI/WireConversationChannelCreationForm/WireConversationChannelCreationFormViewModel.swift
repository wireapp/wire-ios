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

public import SwiftUI
public import WireConversationsAPI

public final class WireConversationChannelCreationFormViewModel: ObservableObject {

    enum Constants {
        static let channelNameMinStringLength = 1
        static let channelNameMaxStringLength = 64
        static let channelNameMaxByteLength = 256

        static let controlSet: CharacterSet = {
            var controlSet = CharacterSet.controlCharacters
            controlSet.remove(Unicode.Scalar(0x200D)!)
            return controlSet
        }()
    }

    typealias TextFieldValue<ValidationError: Error & Equatable> = Result<String, ValidationError>

    public enum ChannelHistoryOption: Equatable, Hashable {
        case off
        case oneDay
        case oneWeek
        case fourWeeks
        case unlimited
        case custom
    }

    public enum ChannelAccessOption: Equatable, Hashable {
        case `public`
        case `private`

        fileprivate func wireChannelAccess(invitePolicy: ChannelInvitePolicyOption) -> WireConversationChannelAccess {
            switch self {
            case .public:
                .public
            case .private:
                .private(invitePolicy.wireChannelInvitePolicy)
            }
        }
    }

    public enum ChannelInvitePolicyOption: Equatable, Hashable {
        case admins
        case adminsAndMembers

        fileprivate var wireChannelInvitePolicy: WireConversationChannelAccess.PrivateChannelInvitePolicy {
            switch self {
            case .admins:
                .admins
            case .adminsAndMembers:
                .adminsAndMembers
            }
        }
    }

    enum ChannelNameValidationError: Error, Equatable {
        case tooShort
        case tooLong
    }

    @Published private(set) var channelName: TextFieldValue<ChannelNameValidationError>

    @Published var channelAccess: ChannelAccessOption
    @Published var channelInvitePolicy: ChannelInvitePolicyOption
    @Published var channelHistoryOption: ChannelHistoryOption
    @Published var servicesAllowed: Bool
    @Published var guestsAllowed: Bool
    @Published var readReceiptsEnabled: Bool

    @Published public private(set) var isFormValid: Bool

    private let onFormValidityUpdate: @Sendable (_ isValid: Bool) -> Void

    public init(
        channelName: String,
        // Channel access is always hard coded to private for now.
        channelAccess: ChannelAccessOption = .private,
        channelInvitePolicy: ChannelInvitePolicyOption = .admins,
        channelHistoryOption: ChannelHistoryOption = .oneDay,
        servicesAllowed: Bool = true,
        guestsAllowed: Bool = true,
        readReceiptsEnabled: Bool = true,
        onFormValidityUpdate: @escaping @Sendable (_ isValid: Bool) -> Void
    ) {
        let channelName = Self.validateChannelName(channelName)

        self.isFormValid = Self.validateForm(channelName: channelName)
        self.channelName = channelName
        self.channelAccess = channelAccess
        self.channelInvitePolicy = channelInvitePolicy
        self.channelHistoryOption = channelHistoryOption
        self.servicesAllowed = servicesAllowed
        self.guestsAllowed = guestsAllowed
        self.readReceiptsEnabled = readReceiptsEnabled

        self.onFormValidityUpdate = onFormValidityUpdate
    }
    
    func isPremium() -> Bool {
        true
    }

    func onChannelNameUpdate(_ value: String) {
        channelName = Self.validateChannelName(value)
        isFormValid = Self.validateForm(channelName: channelName)
        onFormValidityUpdate(isFormValid)
    }

    private static func validateForm(
        channelName: TextFieldValue<ChannelNameValidationError>
    ) -> Bool {
        if case .success = channelName {
            return true
        }
        return false
    }

    private static func validateChannelName(
        _ channelName: String
    ) -> TextFieldValue<ChannelNameValidationError> {
        // From StringLengthValidator (WireUtilities StringLengthValidator.swift:22)
        let trimmed = channelName
            .trimmingCharacters(in: .whitespaces)

        let array = trimmed
            .map { $0.isEmoji || !$0.contains(anyCharacterFrom: Constants.controlSet) ? String($0) : " " }

        if array.count < Constants.channelNameMinStringLength {
            return .failure(.tooShort)
        }
        if array.count > Constants.channelNameMaxStringLength {
            return .failure(.tooLong)
        }
        if trimmed.utf8.count > Constants.channelNameMaxByteLength {
            return .failure(.tooLong)
        }

        return .success(trimmed)
    }

    public func getChannelCreationSettings() -> WireConversationChannelCreationSettings? {
        try? channelName
            .map { value in
                WireConversationChannelCreationSettings(
                    channelName: value,
                    channelAccess: channelAccess.wireChannelAccess(
                        invitePolicy: channelInvitePolicy
                    ),
                    servicesAllowed: servicesAllowed,
                    guestsAllowed: guestsAllowed,
                    readReceiptsEnabled: readReceiptsEnabled
                )
            }
            .get()
    }
}

// TODO: [WPB-17005] When extracting these methods from WireUtilities, we should remove this duplicated code.

// From WireUtilities String+Emoji.swift:19
private extension CharacterSet {
    static let asciiPrintableSet =
        CharacterSet(
            charactersIn: "\u{0020}!\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
        )
    static let unicode = CharacterSet(charactersIn: Unicode.Scalar(Int(0x0000))! ..< Unicode.Scalar(Int(0x10FFFF))!)
    static let asciiUppercaseLetters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    static let asciiLowercaseLetters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz")
    static let asciiStandardCharacters =
        CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789")
}

// From WireUtilities String+Emoji.swift:31
private extension Unicode.Scalar {
    static let cancelTag: Unicode.Scalar = .init(0xE007F)!

    var isEmojiComponentOrMiscSymbol: Bool {
        switch value {
        case 0x200D,       // Zero width joiner
             0x2139,            // the info symobol
             0x2030 ... 0x2BFF,   // Misc symbols
             0x2600 ... 0x27BF,   // Misc symbols, Dingbats
             0xE007F,           // cancelTag
             0xFE00 ... 0xFE0F:   // Variation Selectors
            true
        default:
            false
        }
    }

    var isEmoji: Bool {
        // Unicode General Category S* contains Sc, Sk, Sm & So, we just interest on So(5855 items)
        (CharacterSet.symbols.contains(self) && !CharacterSet.asciiPrintableSet.contains(self)) ||
            isEmojiComponentOrMiscSymbol
    }
}

// From WireUtilities String+Emoji.swift:56
private extension Character {
    var isEmoji: Bool {
        unicodeScalars.contains(where: \.isEmoji)
    }

    func contains(anyCharacterFrom characterSet: CharacterSet) -> Bool {
        unicodeScalars.contains(where: characterSet.contains)
    }
}
