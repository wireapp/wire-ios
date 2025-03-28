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
import UIKit
import WireDesign
import WireConversationsImplementation
import WireConversationsAPI

public final class ChannelAccessHostingController: UIHostingController<ChannelAccessView> {
    
    private let viewModel: ChannelAccessViewModel

    public init(viewModel: ChannelAccessViewModel) {
        self.viewModel = viewModel
        super.init(rootView: ChannelAccessView(viewModel: viewModel))
    }

    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        title = L10n.Localizable.ChannelAccessLevel.navigationTitle
        view.backgroundColor = SemanticColors.View.backgroundDefault
        
        // Back button handled automatically by UINavigationController
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(didTapClose)
        )
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }
}


struct ChannelAccessHostingController_Previews: PreviewProvider {
    static var previews: some View {
        ChannelAccessHostingControllerPreview()
            .edgesIgnoringSafeArea(.all)
            .previewDisplayName("UIKit NavController Preview")
    }
}

struct ChannelAccessHostingControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let state = ChannelAccessSettings(
            isInitiallyPrivate: false,
            accessLevel: .public,
            participantPermission: .adminsAndMembers
        )

        let useCase = ChannelAccessUseCase(settings: state)
        let viewModel = ChannelAccessViewModel(accentColor: .red, useCase: useCase)

        let channelAccessVC = ChannelAccessHostingController(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: channelAccessVC)
        return navController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}


