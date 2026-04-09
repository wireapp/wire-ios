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

import WireDesign
import WireSyncEngine

final class DefaultConversationHeaderView: UIView {

    private static var correlationFormatter: AddressBookCorrelationFormatter = .init(
        lightFont: FontSpec(.small, .light),
        boldFont: FontSpec(.small, .medium),
        color: SemanticColors.Label.textDefault
    )

    private let guestWarningView = GuestAccountWarningView()
    private let guestWarningContainer = UIView()
    private var message: ZMConversationMessage? = nil
    
    private var startedConversationCell: ConversationStartedSystemMessageCellDescription?
    private let startedConversationView = ConversationStartedSystemMessageCellDescription.View()

    init(message: ZMConversationMessage? = nil) {
        self.message = message
        super.init(frame: .zero)
        if let message {
            let description = ConversationStartedSystemMessageCellDescription(message: message)
                self.startedConversationCell = description
                
                // Accedemos a la configuración que generó la descripción
                let config = description.configuration
                
                // Y se la pasamos a la vista.
                // Si '.configuration' da error en la vista, busca el método 'update'
            self.startedConversationView.configure(with: config, animated: false)
        }
        setup()
        createConstraints()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {

        [guestWarningContainer, startedConversationView].forEach(addSubview)

        guestWarningContainer.addSubview(guestWarningView)
        guestWarningContainer.backgroundColor = SemanticColors.View.backgroundGreen
        
        startedConversationView.isHidden = (message == nil)
    }

    private func createConstraints() {
        [
            guestWarningView,
            guestWarningContainer,
            startedConversationView
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            guestWarningContainer.topAnchor.constraint(equalTo: topAnchor),
            guestWarningContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            guestWarningContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            //guestWarningContainer.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor)
            
            // Restricción para la nueva vista al final
                    startedConversationView.topAnchor.constraint(equalTo: guestWarningContainer.bottomAnchor, constant: 24.0),
                    startedConversationView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16.0),
                    startedConversationView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16.0),
                    
                    // MUY IMPORTANTE: Esta es la que define el final de la vista total
                    startedConversationView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20.0)
        ])

        guestWarningView.fitIn(view: guestWarningContainer, insets: .init(top: 12, left: 16, bottom: 12, right: 16))
    }
}
