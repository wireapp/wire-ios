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

@MainActor
public struct AccountImageGenerator: AccountImageGeneratorProtocol {

    // MARK: - Public Properties

    public var textColor: UIColor = .init { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .white : .black
    }

    public var backgroundColor: UIColor = .init { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? .black : .white
    }

    // MARK: - Private Properties

    private let renderer = InitialsRenderer(frame: .init(x: 0, y: 0, width: 26, height: 26))

    // MARK: - Life Cycle

    public init() {}

    // MARK: - Methods

    public func createImage(initials: String) async -> UIImage {
        let initials = initials.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !initials.isEmpty else { return .init() }

        renderer.backgroundColor = backgroundColor
        renderer.initials = initials
        return renderer.renderImage()
    }
}

// MARK: -

private final class InitialsRenderer: UIView {

    fileprivate var initials: String {
        get { initialsLabel.text ?? "" }
        set { initialsLabel.text = newValue }
    }

    private let initialsLabel = UILabel()

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        setupLabel(initials)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupLabel(_ initials: String) {
        initialsLabel.font = .systemFont(ofSize: 13, weight: .light)
        initialsLabel.textAlignment = .center
        initialsLabel.text = initials
        initialsLabel.frame = bounds.insetBy(dx: 2, dy: 2)
        initialsLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        initialsLabel.adjustsFontSizeToFitWidth = true
        addSubview(initialsLabel)
    }

    // MARK: - Methods

    fileprivate func renderImage() -> UIImage {
        setNeedsLayout()
        layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        return UIGraphicsImageRenderer(size: bounds.size, format: format).image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    AccountImageGeneratorPreview("WW")
}
