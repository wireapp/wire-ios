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

public import Foundation
public import Combine
import SwiftUI
import WireFoundation
public import WireMessagingDomain

public final class ConversationChannelCreationFormViewModel: ObservableObject {

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

    public enum ChannelAccessOption: Equatable, Hashable {
        case `public`
        case `private`

        fileprivate func wireChannelAccess(invitePolicy: ChannelInvitePolicyOption) -> ConversationChannelAccess {
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

        fileprivate var wireChannelInvitePolicy: ConversationChannelAccess.PrivateChannelInvitePolicy {
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
    @Published var channelHistoryOptionCustom: ChannelHistoryOption.Custom = .init()
    @Published var showUpgradeBanner: Bool = false
    @Published var appsAllowed: Bool
    @Published var guestsAllowed: Bool
    @Published var readReceiptsEnabled: Bool
    @Published var fileManagementEnabled: Bool = false
    @Published public private(set) var isFormValid: Bool

    let teamsURL: URL
    let isWireDriveEnabled: Bool
    private let onFormValidityUpdate: @Sendable (_ isValid: Bool) -> Void
    private let isUserPremium: Bool
    private var subscriptions = Set<AnyCancellable>()

    public init(
        channelName: String,
        // Channel access is always hard coded to private for now.
        channelAccess: ChannelAccessOption = .private,
        channelInvitePolicy: ChannelInvitePolicyOption = .admins,
        channelHistoryOption: ChannelHistoryOption = .off,
        appsAllowed: Bool = true,
        guestsAllowed: Bool = true,
        readReceiptsEnabled: Bool = true,
        isUserPremium: Bool,
        isWireDriveEnabled: Bool,
        teamsURL: URL,
        onFormValidityUpdate: @escaping @Sendable (_ isValid: Bool) -> Void
    ) {
        let channelName = Self.validateChannelName(channelName)

        self.isFormValid = Self.validateForm(channelName: channelName)
        self.channelName = channelName
        self.channelAccess = channelAccess
        self.channelInvitePolicy = channelInvitePolicy
        self.channelHistoryOption = channelHistoryOption
        self.appsAllowed = appsAllowed
        self.guestsAllowed = guestsAllowed
        self.readReceiptsEnabled = readReceiptsEnabled
        self.isUserPremium = isUserPremium
        self.isWireDriveEnabled = isWireDriveEnabled
        self.teamsURL = teamsURL
        self.onFormValidityUpdate = onFormValidityUpdate

        bind()
    }

    // MARK: History sharing

    func isChannelHistoryFeatureEnabled() -> Bool {
        // TODO: [WPB-19065] - Move DeveloperFlag from WireUtilities to WireFoundation
        UserDefaults.standard.object(
            forKey: "channelsHistory"
        ) as? Bool ?? false
    }

    private func bind() {
        $channelHistoryOption
            .filter { [self] in $0 == .custom && !isUserPremium }
            .map { _ in true }
            .assign(to: \.showUpgradeBanner, on: self)
            .store(in: &subscriptions)
    }

    func channelHistoryAvailableOptions() -> [ChannelHistoryOption] {
        if isUserPremium {
            [.off, .oneDay, .oneWeek, .fourWeeks, .unlimited, .custom]
        } else {
            [.off, .oneDay, .custom]
        }
    }

    func showChannelCustomHistoryPickers() -> Bool {
        channelHistoryOption == .custom && isUserPremium
    }

    func hideUpgradeBanner() {
        showUpgradeBanner = false
        channelHistoryOption = .oneDay
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

    public func getChannelCreationSettings() -> ConversationChannelCreationSettings? {

        try? channelName
            .map { value in
                ConversationChannelCreationSettings(
                    channelName: value,
                    channelAccess: channelAccess.wireChannelAccess(
                        invitePolicy: channelInvitePolicy
                    ),
                    appsAllowed: appsAllowed,
                    guestsAllowed: guestsAllowed,
                    readReceiptsEnabled: readReceiptsEnabled,
                    historyDepth: getHistoryDepth(),
                    fileManagementEnabled: fileManagementEnabled
                )
            }
            .get()
    }

    private func getHistoryDepth() -> String? {
        switch channelHistoryOption {
        case .off:
            .none
        case .oneDay:
            "One day"
        case .oneWeek:
            "One week"
        case .fourWeeks:
            "Four weeks"
        case .unlimited:
            "Unlimited"
        case .custom:
            "\(channelHistoryOptionCustom.value) \(channelHistoryOptionCustom.unit == .days ? "days" : "weeks")"
        }
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

extension ChannelHistoryOption.Custom.Unit {
    var title: String {
        switch self {
        case .days:
            L10n.Localizable.Conversation.ChannelHistory.CustomPicker.days
        case .weeks:
            L10n.Localizable.Conversation.ChannelHistory.CustomPicker.weeks
        }
    }
}
