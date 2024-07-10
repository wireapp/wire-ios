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

import SwiftUI
import UIKit
import WireDataModel
import WireSyncEngine

final class RenameGroupSectionController: NSObject, CollectionViewSectionController {
    enum CellIndex: Int {
        case groupDetailsRenameCell
        case groupIconCell
    }

    weak var delegate: RenameGroupSectionControllerDelegate?

    private var validName: String?
    private var conversation: GroupDetailsConversationType
    private var renameCell: GroupDetailsRenameCell?
    private var token: AnyObject?
    private var sizingFooter = SectionFooter(frame: .zero)
    let userSession: UserSession

    var isHidden: Bool {
        return false
    }

    init(conversation: GroupDetailsConversationType, userSession: UserSession) {
        self.conversation = conversation
        self.userSession = userSession
        super.init()

        if let conversation = conversation as? ZMConversation {
            token = ConversationChangeInfo.add(observer: self, for: conversation)
        }
    }

    func focus() {
        guard conversation.isSelfAnActiveMember else { return }
        renameCell?.titleTextField.becomeFirstResponder()
    }

    func prepareForUse(in collectionView: UICollectionView?) {
        collectionView.flatMap(GroupDetailsRenameCell.register)
        collectionView.flatMap(UICollectionViewCell.register)
        collectionView?.register(SectionFooter.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "SectionFooter")
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch CellIndex(rawValue: indexPath.row) {
        case .groupDetailsRenameCell:
            return groupDetailsRenameCell(for: collectionView, at: indexPath)
        case .groupIconCell:
            return groupIconCell(for: collectionView, at: indexPath)
        default:
            fatalError("cell doesn't exist")
        }
    }

    private func groupIconCell(for collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: UICollectionViewCell.self, for: indexPath)
        if #available(iOS 16.0, *) {
            cell.contentConfiguration = UIHostingConfiguration(content: {
                GroupIconCell(color: conversation.groupColor,
                              emoji: conversation.groupEmoji)
            })
        } else {
            // Fallback on earlier versions
        }
        return cell
    }

    private func groupDetailsRenameCell(for collectionView: UICollectionView, at indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(ofType: GroupDetailsRenameCell.self, for: indexPath)

        if let user = SelfUser.provider?.providedSelfUser {
            cell.configure(for: conversation, editable: user.canModifyTitle(in: conversation))
        } else {
            assertionFailure("expected available 'user'!")
        }

        cell.titleTextField.textFieldDelegate = self
        renameCell = cell
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "SectionFooter", for: indexPath)
        (view as? SectionFooter)?.titleLabel.text = L10n.Localizable.Participants.Section.Name.footer(ZMConversation.maxParticipants)
        return view
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width, height: 56)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard
            let user = SelfUser.provider?.providedSelfUser,
            user.hasTeam
        else { return .zero }

        sizingFooter.titleLabel.text = L10n.Localizable.Participants.Section.Name.footer(ZMConversation.maxParticipants)
        sizingFooter.size(fittingWidth: collectionView.bounds.width)
        return sizingFooter.bounds.size
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch CellIndex(rawValue: indexPath.row) {
        case .groupDetailsRenameCell:
            focus()
        case .groupIconCell:
            delegate?.presentGroupIconOptions(animated: true)
        default:
            fatalError("cell doesn't exist")
        }

    }
}

extension RenameGroupSectionController: ZMConversationObserver {

    func conversationDidChange(_ changeInfo: ConversationChangeInfo) {
        guard changeInfo.securityLevelChanged || changeInfo.nameChanged else { return }

        guard let conversation = conversation as? ZMConversation else { return }

        renameCell?.configure(for: conversation, editable: ZMUser.selfUser()?.canModifyTitle(in: conversation) ?? false)
    }

}

extension RenameGroupSectionController: SimpleTextFieldDelegate {

    func textFieldReturnPressed(_ textField: SimpleTextField) {
        guard let value = textField.value else { return }

        switch  value {
        case .valid(let name):
            validName = name
            textField.endEditing(true)
        case .error:
            // TODO show error
            textField.endEditing(true)
        }
    }

    func textField(_ textField: SimpleTextField, valueChanged value: SimpleTextField.Value) {

    }

    func textFieldDidBeginEditing(_ textField: SimpleTextField) {
        renameCell?.accessoryIconView.isHidden = true
    }

    func textFieldDidEndEditing(_ textField: SimpleTextField) {
        if let newName = validName {
            userSession.enqueue {
                self.conversation.userDefinedName = newName
            }
        } else {
            textField.text = conversation.displayName
        }

        renameCell?.accessoryIconView.isHidden = false
    }

}

struct GroupIconCell: View {
    var color: String?
    var emoji: String?

    var body: some View {
        HStack {
            Text("Group Icon")
                .font(Font.textStyle(.body1))
                .fontWeight(.bold)
            Spacer()
            if let color {
                GroupIconView(color: color, emoji: emoji)
            }
            Image(systemName: "chevron.right")
        }
        .background(Color.white)
        .frame(height: 44)
    }
}

struct GroupIconView: View {
    let size: CGSize = .init(width: 40, height: 40)
    var color: String?
    var emoji: String?

    var body: some View {
        Text(emoji ?? "")
            .fontWeight(.bold)
            .font(Font.textStyle(.body1))
            .padding(5)
            .background(backgroundColor)
            .frame(width: size.width, height: size.height)
            .cornerRadius(5)
    }

    // TODO: add dark / light support
    var backgroundColor: Color {
        color != nil ? Color(hex: color!) : Color.clear
    }
}

#Preview {
    GroupIconCell(color: "d733ff", emoji: "💩")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
