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
import WireFoundation

@MainActor
func SidebarViewControllerPreview() -> UIViewController {
    let splitViewController = UISplitViewController(style: .tripleColumn)
    let sidebarViewController = SidebarViewController { accountImage, availability in
        AnyView(MockAccountImageView(accountImage: accountImage, availability: availability))
    }
    sidebarViewController.accountInfo.displayName = "Firstname Lastname"
    sidebarViewController.accountInfo.username = "@username"
    sidebarViewController.wireTextStyleMapping = PreviewTextStyleMapping()
    splitViewController.setViewController(sidebarViewController, for: .primary)
    splitViewController.setViewController(EmptyViewController(), for: .supplementary)
    splitViewController.setViewController(EmptyViewController(), for: .secondary)
    splitViewController.setViewController(HintViewController("No sidebar visible!"), for: .compact)
    splitViewController.preferredSplitBehavior = .tile
    splitViewController.preferredDisplayMode = .twoBesideSecondary
    splitViewController.preferredPrimaryColumnWidth = 260
    splitViewController.preferredSupplementaryColumnWidth = 320
    splitViewController.view.backgroundColor = .init(white: 0.9, alpha: 1)

    return splitViewController
}

private final class EmptyViewController: UIHostingController<AnyView> {
    convenience init() { self.init(rootView: AnyView(EmptyView())) }
    private struct EmptyView: View {
        var body: some View {
            VStack(spacing: 0) {
                Rectangle()
                    .foregroundStyle(Color(uiColor: .systemGray5))
                    .frame(height: 22)
                Rectangle()
                    .foregroundStyle(Color(uiColor: .systemBackground))
            }.ignoresSafeArea()
        }
    }
}

final class HintViewController: UIHostingController<Text> {
    convenience init(_ hint: String) {
        self.init(rootView: Text(verbatim: hint).font(.title2))
    }
}

private func PreviewTextStyleMapping() -> WireTextStyleMapping {
    .init { _ in
        fatalError("not implemented for preview yet")
    } fontMapping: { textStyle in
        switch textStyle {
        case .h2:
            .title3.bold()
        default:
            fatalError("not implemented for preview yet")
        }
    }
}
