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

import Foundation
import SwiftUI

public class SwitchBackendConfirmationHostingController: UIHostingController<SwitchBackendConfirmationView_V2> {

    private let viewModel: SwitchBackendConfirmationViewModel_V2

    public init(viewModel: SwitchBackendConfirmationViewModel_V2) {
        self.viewModel = viewModel

        super.init(rootView: SwitchBackendConfirmationView_V2(viewModel: viewModel, onShowDetails: {}))
        rootView = SwitchBackendConfirmationView_V2(
            viewModel: viewModel,
            onShowDetails: changeViewState
        )
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func changeViewState() {
        guard let sheet = sheetPresentationController else {
            return
        }
        let oldValue = sheet.selectedDetentIdentifier ?? .medium
        sheet.animateChanges {
            sheet.selectedDetentIdentifier = oldValue.oppositeValue
        }
    }

}

private extension UISheetPresentationController.Detent.Identifier {

    var oppositeValue: UISheetPresentationController.Detent.Identifier {
        switch self {
        case .medium:
                .large
        case .large:
                .medium
        default:
            fatalError("Unsupported value")
        }
    }

}
