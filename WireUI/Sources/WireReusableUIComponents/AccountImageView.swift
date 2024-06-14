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

private let imageHeight: CGFloat = 27
private let imageBorderWidth: CGFloat = 1
private let availabilityIndicatorRadius: CGFloat = 4.375
private let availabilityIndicatorBorderWidth: CGFloat = 2
private let teamAccountImageCornerRadius: CGFloat = 6

/// Displays the image of a user account plus optional availability.
public final class AccountImageView: UIView {

    // MARK: - Public Properties

    public var accountImage = UIImage() {
        didSet { updateAccountImage() }
    }

    public var accountType = AccountType.user {
        didSet { updateClipping() }
    }

    public var availability: Availability? {
        didSet { updateAvailabilityIndicator() }
    }

    // MARK: - Private Properties

    private let imageView = UIImageView()

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    // MARK: - Methods

    private func setupSubviews() {

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: imageHeight),
            imageView.heightAnchor.constraint(equalToConstant: imageHeight),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        updateAccountImage()
        updateClipping()
        updateAvailabilityIndicator()
    }

    private func updateAccountImage() {
        imageView.image = accountImage
    }

    private func updateClipping() {
        switch accountType {
        case .user:
            imageView.layer.cornerRadius = imageHeight / 2
        case .team:
            imageView.layer.cornerRadius = teamAccountImageCornerRadius
        }
    }

    private func updateAvailabilityIndicator() {

        if availability == .none {
            return imageView.layer.mask = .none
        }

        // draw a rect over the total bounds (for inverting the arc)
        let maskPath = UIBezierPath(
            rect: .init(x: 0, y: 0, width: imageHeight, height: imageHeight)
        )
        // draw the circle to clip from the image
        maskPath.addArc(
            withCenter: .init(
                x: imageHeight - availabilityIndicatorRadius / 2,
                y: imageHeight - availabilityIndicatorRadius / 2
            ),
            radius: availabilityIndicatorRadius + 2 * availabilityIndicatorBorderWidth,
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )

        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        maskLayer.fillRule = .evenOdd

        imageView.layer.mask = maskLayer
    }

    // MARK: - Nested Types

    public enum AccountType: CaseIterable {
        /// The account image will be clipped using a circle shape.
        case user
        /// The account image will be clipped using a round rectangle shape.
        case team
    }

    public enum Availability: CaseIterable {
        case available, busy, away
    }
}

// MARK: - Previews

private typealias AccountType = AccountImageView.AccountType
private typealias Availability = AccountImageView.Availability

struct AccountImageView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            ForEach(AccountType.allCases, id: \.self) { accountType in

                let accountImage = switch accountType {
                case .user: userAccountImage
                case .team: teamAccountImage
                }

                AccountImageViewRepresentable(accountImage, accountType, .none)
                    .previewDisplayName("\(accountType)")
                ForEach(Availability.allCases, id: \.self) { availability in
                    AccountImageViewRepresentable(accountImage, accountType, availability)
                        .previewDisplayName("\(accountType) - \(availability)")
                }
            }
        }
        .background(.gray)
    }

    static let userAccountImage = {
        let url = URL(string: "https://wire.com/hs-fs/hubfs/Keyvisual_Homepage_medium.jpg?height=135")!
        let data = try! Data(contentsOf: url)
        return UIImage(data: data)!
    }()

    static let teamAccountImage = {
        let url = URL(string: "https://wire.com/hs-fs/hubfs/WIRE_Logo_rgb_black.png?width=135")!
        let data = try! Data(contentsOf: url)
        return UIImage(data: data)!
    }()
}

private struct AccountImageViewRepresentable: UIViewRepresentable {

    private(set) var accountImage: UIImage
    private(set) var accountType: AccountType
    private(set) var availability: Availability?

    init(
        _ accountImage: UIImage,
        _ accountType: AccountType,
        _ availability: Availability?
    ) {
        self.accountImage = accountImage
        self.accountType = accountType
        self.availability = availability
    }

    func makeUIView(context: Context) -> AccountImageView {
        let view = AccountImageView()
        view.accountImage = accountImage
        view.accountType = accountType
        view.availability = availability
        return view
    }

    func updateUIView(_ view: AccountImageView, context: Context) {
        view.accountImage = accountImage
        view.accountType = accountType
        view.availability = availability
    }
}
