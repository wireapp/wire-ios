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
import WireDesign
import WireReusableUIComponents

public struct SelfProfileViewCallToActionBanner: View {

    public enum Action: Sendable {
        case createWireTeam
    }

    let actionCallback: @Sendable (Action) -> Void

    public init(actionCallback: @escaping @Sendable (Action) -> Void) {
        self.actionCallback = actionCallback
    }

    public var body: some View {
        // if the device screen width is less than 400 (iPhone mini is 375), use a smaller padding
        contentView(actionCallback: actionCallback)
            .padding(8)
            .bannerBackground()
    }
}

@MainActor
@ViewBuilder fileprivate func contentView(
    actionCallback: @escaping @Sendable (SelfProfileViewCallToActionBanner.Action) -> Void
) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        Label(title: {
            Text(String.localized(key: "individualToTeam.banner.title", bundle: .module))
                .wireTextStyle(.h5)
        }, icon: {
            Image.info
        })
        .fontWeight(.bold)
        Text(String.localized(key: "individualToTeam.banner.body", bundle: .module))
            .wireTextStyle(.subline1)
            .lineLimit(nil)
        Button(
            action: { actionCallback(.createWireTeam) },
            label: {
                Text(String.localized(key: "individualToTeam.banner.button", bundle: .module))
            }
        )
        .wireButtonStyle(.secondary)
    }
}

//fileprivate struct AdaptivePaddingModifier: ViewModifier {
//    let edges: Edge.Set
//
//    init (edges: Edge.Set) {
//        self.edges = edges
//    }
//
//    func body(content: Content) -> some View {
//        if UIScreen.main.bounds.width < 400 {
//            content.padding(.all, 12)
//        } else {
//            content.padding(edges)
//        }
//    }
//}

fileprivate extension View {
    func bannerBackground() -> some View {
        self.background {
            if #available(iOS 17.0, *) {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.blue, lineWidth: 1)
                    .fill(.blue.opacity(0.3))
            } else {
                Color.blue.opacity(0.3)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .border(.blue, width: 1)
            }
        }
    }

//    func adaptivePadding(_ edges: Edge.Set = .all) -> some View {
//        self.modifier(AdaptivePaddingModifier(edges: edges))
//    }
}

public class SelfProfileViewCallToActionBannerHostingController: UIHostingController<SelfProfileViewCallToActionBanner> {
    public init(actionCallback: @escaping @Sendable (SelfProfileViewCallToActionBanner.Action) -> Void) {
        super.init(rootView: SelfProfileViewCallToActionBanner(actionCallback: actionCallback))
        self.view.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


@available(iOS 17.0, *)
#Preview {
    SelfProfileViewCallToActionBanner(actionCallback: { _ in })
}

