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

final class SidebarViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // navigationItem.title = "Sidebar"

        view.backgroundColor = .init(red: 0xED / 255.0, green: 0xEF / 255.0, blue: 0xF0 / 255.0, alpha: 1)

        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(v)
        v.leadingAnchor.constraint(equalToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 1).isActive = true
        v.topAnchor.constraint(equalToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1).isActive = true
        view.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: v.trailingAnchor, multiplier: 1).isActive = true
        view.safeAreaLayoutGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: v.bottomAnchor, multiplier: 1).isActive = true

        view.setNeedsLayout()
        view.layoutIfNeeded()

        let imageViews = [
            UIImageView(image: .init(resource: .sidebar0))
//            UIImageView(image: .init(resource: .sidebar1)),
//            UIImageView(image: .init(resource: .sidebar2))
        ]
        imageViews.forEach { imageView in
            imageView.contentMode = .scaleAspectFit
            view.addSubview(imageView)
        }
        imageViews[0].autoresizingMask = [.flexibleBottomMargin, .flexibleWidth]
        v.addSubview(imageViews[0])
        imageViews[0].frame = .init(origin: .zero, size: .init(width: v.frame.width, height: imageViews[0].image!.size.height * v.frame.width / imageViews[0].image!.size.width))
        print(imageViews[0].frame)
        // imageViews[0].frame = .init(origin: .zero, size: .init(width: view.frame.width, height: <#T##CGFloat#>))
//        imageViews[0].leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        imageViews[0].topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//        view.trailingAnchor.constraint(equalTo: imageViews[0].trailingAnchor).isActive = true
    }
}

struct SidebarView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> SidebarViewController {
        .init()
    }

    func updateUIViewController(_ uiViewController: SidebarViewController, context: Context) {}
}

#Preview {
    SidebarView()
}
