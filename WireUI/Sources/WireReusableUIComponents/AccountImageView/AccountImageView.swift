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

private let accountImageHeight: CGFloat = 26
private let accountImageBorderWidth: CGFloat = 1
private let availabilityIndicatorRadius: CGFloat = 8.75 / 2
private let availabilityIndicatorBorderWidth: CGFloat = 2
private let availabilityIndicatorCenterOffset = accountImageBorderWidth * 2 + accountImageHeight - availabilityIndicatorRadius
private let teamAccountImageCornerRadius: CGFloat = 6

/// Displays the image of a user account plus optional availability.
public final class AccountImageView: UIView {

    // MARK: - Public Properties

    public var accountImage = UIImage() {
        didSet { updateAccountImage() }
    }

    public var accountType = AccountType.user {
        didSet { updateShape() }
    }

    public var availability: Availability? {
        didSet { updateAvailabilityIndicator() }
    }

    // MARK: - Private Properties

    private let accountImageView = UIImageView()
    private let availabilityIndicatorView = AvailabilityIndicatorView()

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateAccountImageBorder()
    }

    // MARK: - Methods

    private func setupSubviews() {

        // wrapper of the image view which applies the border on its layer
        let accountImageViewWrapper = UIView()
        accountImageViewWrapper.translatesAutoresizingMaskIntoConstraints = false
        accountImageViewWrapper.clipsToBounds = true
        addSubview(accountImageViewWrapper)
        NSLayoutConstraint.activate([
            accountImageViewWrapper.centerXAnchor.constraint(equalTo: centerXAnchor),
            accountImageViewWrapper.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // the image view which displays the account image
        accountImageView.contentMode = .scaleAspectFill
        accountImageView.translatesAutoresizingMaskIntoConstraints = false
        accountImageViewWrapper.addSubview(accountImageView)
        NSLayoutConstraint.activate([
            accountImageView.widthAnchor.constraint(equalToConstant: accountImageHeight),
            accountImageView.heightAnchor.constraint(equalToConstant: accountImageHeight),
            accountImageView.leadingAnchor.constraint(equalTo: accountImageViewWrapper.leadingAnchor, constant: accountImageBorderWidth),
            accountImageView.topAnchor.constraint(equalTo: accountImageViewWrapper.topAnchor, constant: accountImageBorderWidth),
            accountImageViewWrapper.trailingAnchor.constraint(equalTo: accountImageView.trailingAnchor, constant: accountImageBorderWidth),
            accountImageViewWrapper.bottomAnchor.constraint(equalTo: accountImageView.bottomAnchor, constant: accountImageBorderWidth)
        ])

        // view which renders the availability status
        availabilityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(availabilityIndicatorView)
        NSLayoutConstraint.activate([
            availabilityIndicatorView.widthAnchor.constraint(equalToConstant: availabilityIndicatorRadius * 2),
            availabilityIndicatorView.heightAnchor.constraint(equalToConstant: availabilityIndicatorRadius * 2),
            accountImageViewWrapper.trailingAnchor.constraint(equalTo: availabilityIndicatorView.trailingAnchor),
            accountImageViewWrapper.bottomAnchor.constraint(equalTo: availabilityIndicatorView.bottomAnchor)
        ])

        updateAccountImage()
        updateShape()
        updateAvailabilityIndicator()
    }

    private func updateAccountImageBorder() {
        guard let accountImageViewWrapper = accountImageView.superview else { return }

        accountImageViewWrapper.layer.borderWidth = 1
        // #dce0e3 Gray-40 light
        // #34373d Gray-90 dark
        accountImageViewWrapper.layer.borderColor = UIColor {
            $0.userInterfaceStyle == .dark
            ? .init(red: 0.20, green: 0.22, blue: 0.24, alpha: 1.00)
            : .init(red: 0.86, green: 0.88, blue: 0.89, alpha: 1)
        }.cgColor
    }

    private func updateAccountImage() {
        accountImageView.image = accountImage
    }

    private func updateShape() {
        guard let accountImageViewWrapper = accountImageView.superview else { return }

        switch accountType {
        case .user:
            accountImageViewWrapper.layer.cornerRadius = accountImageHeight / 2 + accountImageBorderWidth
        case .team:
            accountImageViewWrapper.layer.cornerRadius = teamAccountImageCornerRadius
        }
    }

    private func updateAvailabilityIndicator() {

        availabilityIndicatorView.availability = availability

        if availability == .none {
            // remove clipping
            accountImageView.layer.mask = .none
            return
        }

        // draw a rect over the total bounds (for inverting the arc)
        let imageWrapperViewHeight = accountImageBorderWidth * 2 + accountImageHeight
        let maskPath = UIBezierPath(
            rect: .init(origin: .zero, size: .init(width: imageWrapperViewHeight, height: imageWrapperViewHeight))
        )
        // crop a circle shape from the image
        let center = CGPoint(x: availabilityIndicatorCenterOffset, y: availabilityIndicatorCenterOffset)
        let radius = availabilityIndicatorRadius + availabilityIndicatorBorderWidth
        maskPath.addArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: true)

        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        maskLayer.fillRule = .evenOdd
        accountImageView.superview?.layer.mask = maskLayer
    }

    // MARK: - Nested Types

    public enum AccountType: CaseIterable {
        /// The account image will be clipped using a circle shape.
        case user
        /// The account image will be clipped using a round rectangle shape.
        case team
    }
}

// MARK: - Previews

private typealias AccountType = AccountImageView.AccountType

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
        .background(Color(UIColor.systemGray2))
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
        view.transform = .init(scaleX: 6, y: 6)
        return view
    }

    func updateUIView(_ view: AccountImageView, context: Context) {
        view.accountImage = accountImage
        view.accountType = accountType
        view.availability = availability
    }
}
