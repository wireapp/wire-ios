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

import UIKit
import WireReusableUIComponents

extension AccountImageView {

    func setTeamImageViewContent(_ teamImageViewContent: TeamImageView.Content) {

        accountType = .team

        switch teamImageViewContent {
        case .teamImage(let data):
            if let accountImage = UIImage(data: data) {
                self.accountImage = accountImage
            } else {
                self.accountImage = InitialsRenderer("").renderImage()
            }
        case .teamName(let name):
            let initials = name.first.map { "\($0)" } ?? ""
            self.accountImage = InitialsRenderer(initials).renderImage()
        }
    }
}

private final class InitialsRenderer: UIView {

    fileprivate init(_ initials: String) {
        super.init(frame: .init(x: 0, y: 0, width: 50, height: 50))
        backgroundColor = .green
        setupLabel(initials)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupLabel(_ initials: String) {
        let label = UILabel()
        label.text = initials
        label.frame = bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(label)
    }

    fileprivate func renderImage() -> UIImage {

        setNeedsLayout()
        layoutIfNeeded()

        let factor: CGFloat = 3
        let size = CGSize(width: bounds.width * factor, height: bounds.height * factor)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        return UIGraphicsImageRenderer(size: bounds.size, format: format).image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
