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

package import SwiftUI
import WireDesign

package final class FilesHostingController: UIHostingController<FilesView> {

    private typealias Strings = L10n.Localizable.Conversation.WireCells
    private typealias Accessibility = L10n.Accessibility.Conversation.WireCells

    private let viewModel: FilesViewModel

    public init(viewModel: FilesViewModel) {
        self.viewModel = viewModel
        super.init(rootView: FilesView(viewModel: viewModel))
    }

    @available(*, unavailable)
    @MainActor @objc
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
