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
import WireDesign

// MARK: Constants

/// Used for the intrinsic content size
private let accountImageHeight: CGFloat = 26
private let accountImageBorderWidth: CGFloat = 1
private let teamAccountImageCornerRadius: CGFloat = 6
private let accountImageViewBorderColor = ColorTheme.Strokes.outline

private let availabilityIndicatorDiameterFraction = CGFloat(10) / 32

// MARK: -

/// Displays the image of a user account plus optional availability.
public final class AccountImageView: UIView {

    // MARK: - Public Properties

    public var accountImage = UIImage() {
        didSet { updateAccountImage() }
    }

    public var isTeamAccount = false {
        didSet { updateShape() }
    }

    public var availability: Availability? {
        didSet { updateAvailabilityIndicator() }
    }

    // MARK: - Private Properties

    private let accountImageView = UIImageView()
    private let availabilityIndicatorView = AvailabilityIndicatorView()

    override public var intrinsicContentSize: CGSize {
        .init(
            width: accountImageBorderWidth * 2 + accountImageHeight,
            height: accountImageBorderWidth * 2 + accountImageHeight
        )
    }

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        updateAccountImageBorder()
        updateShape()
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #unavailable(iOS 17.0), previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateAvailabilityIndicator()
        }
    }

    // MARK: - Methods

    private func setupSubviews() {
        // wrapper of the image view which applies the border on its layer
        let accountImageViewWrapper = UIView()
        accountImageViewWrapper.translatesAutoresizingMaskIntoConstraints = false
        accountImageViewWrapper.clipsToBounds = true
        addSubview(accountImageViewWrapper)
        var constraints = [
            // make sure it's in the center, even if the surrounding view is not a square
            accountImageViewWrapper.centerXAnchor.constraint(equalTo: centerXAnchor),
            accountImageViewWrapper.centerYAnchor.constraint(equalTo: centerYAnchor),
            // aspect ratio 1:1
            accountImageViewWrapper.widthAnchor.constraint(equalTo: accountImageViewWrapper.heightAnchor),
            // ensure the image wrapper is always inside its container
            accountImageViewWrapper.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            accountImageViewWrapper.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            trailingAnchor.constraint(greaterThanOrEqualTo: accountImageViewWrapper.trailingAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: accountImageViewWrapper.bottomAnchor),
            // enlarge the image wrapper as much as possible
            accountImageViewWrapper.leadingAnchor.constraint(equalTo: leadingAnchor), // lower priority
            accountImageViewWrapper.topAnchor.constraint(equalTo: topAnchor), // lower priority
            trailingAnchor.constraint(equalTo: accountImageViewWrapper.trailingAnchor), // lower priority
            bottomAnchor.constraint(equalTo: accountImageViewWrapper.bottomAnchor) // lower priority
        ]
        constraints[constraints.endIndex - 4 ..< constraints.endIndex].forEach { $0.priority = .defaultHigh }
        NSLayoutConstraint.activate(constraints)

        // the image view which displays the account image
        accountImageView.contentMode = .scaleAspectFill
        accountImageView.translatesAutoresizingMaskIntoConstraints = false
        accountImageViewWrapper.addSubview(accountImageView)
        constraints = [
            accountImageView.widthAnchor.constraint(equalToConstant: accountImageHeight), // fallback, lower priority
            accountImageView.heightAnchor.constraint(equalToConstant: accountImageHeight), // fallback, lower priority
            accountImageView.leadingAnchor.constraint(equalTo: accountImageViewWrapper.leadingAnchor, constant: accountImageBorderWidth),
            accountImageView.topAnchor.constraint(equalTo: accountImageViewWrapper.topAnchor, constant: accountImageBorderWidth),
            accountImageViewWrapper.trailingAnchor.constraint(equalTo: accountImageView.trailingAnchor, constant: accountImageBorderWidth),
            accountImageViewWrapper.bottomAnchor.constraint(equalTo: accountImageView.bottomAnchor, constant: accountImageBorderWidth)
        ]
        constraints[0 ... 1].forEach { $0.priority = .defaultLow }
        NSLayoutConstraint.activate(constraints)

        // view which renders the availability status
        availabilityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(availabilityIndicatorView)
        NSLayoutConstraint.activate([
            availabilityIndicatorView.widthAnchor.constraint(equalTo: accountImageViewWrapper.widthAnchor, multiplier: availabilityIndicatorDiameterFraction),
            availabilityIndicatorView.heightAnchor.constraint(equalTo: accountImageViewWrapper.heightAnchor, multiplier: availabilityIndicatorDiameterFraction),
            accountImageViewWrapper.trailingAnchor.constraint(equalTo: availabilityIndicatorView.trailingAnchor),
            accountImageViewWrapper.bottomAnchor.constraint(equalTo: availabilityIndicatorView.bottomAnchor)
        ])

        updateAccountImage()
        updateShape()
        updateAvailabilityIndicator()

        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _: UITraitCollection) in
                self.updateAvailabilityIndicator()
            }
        }
    }

    private func updateAccountImageBorder() {
        guard let accountImageViewWrapper = accountImageView.superview else { return }

        accountImageViewWrapper.layer.borderWidth = 1
        accountImageViewWrapper.layer.borderColor = accountImageViewBorderColor.cgColor
    }

    private func updateAccountImage() {
        accountImageView.image = accountImage
    }

    private func updateShape() {
        guard let accountImageViewWrapper = accountImageView.superview else { return }

        accountImageViewWrapper.layer.cornerRadius = if isTeamAccount {
            teamAccountImageCornerRadius
        } else {
            accountImageViewWrapper.frame.height / 2
        }
    }

    private func updateAvailabilityIndicator() {
        if availabilityIndicatorView.availability != availability {
            availabilityIndicatorView.availability = availability
        }

        if availability == .none || traitCollection.userInterfaceStyle == .dark {
            // remove clipping
            accountImageView.superview?.layer.mask = .none
            return
        }
    }
}

// MARK: - Convenience Init

public extension AccountImageView {

    convenience init(
        accountImage: UIImage,
        isTeamAccount: Bool,
        availability: Availability?
    ) {
        self.init()

        self.accountImage = accountImage
        self.isTeamAccount = isTeamAccount
        self.availability = availability

        updateAccountImage()
        updateShape()
        updateAvailabilityIndicator()
    }
}

// MARK: - Previews

@available(iOS 16.0, *)
struct AccountImageView_Previews: PreviewProvider {

    static var previews: some View {
        Group {

            previewWithNavigationBar(.none)

            ForEach(Availability.allCases, id: \.self) { availability in
                previewWithNavigationBar(availability)
                    .previewDisplayName("\(availability)")
            }
        }
    }

    @ViewBuilder
    static func previewWithNavigationBar(_ availability: Availability?) -> some View {
        let accountImage = UIImage.from(solidColor: .init(red: 0, green: 0.73, blue: 0.87, alpha: 1))
        NavigationStack {
            AccountImageViewRepresentable(accountImage, availability)
                // set a frame in order check that it scales,
                // ensure it scales with "aspectFit" content mode
                .frame(width: 32, height: 50)
                // make the frame visible in order to be able
                // to check the alignment and size
                .background(Color(UIColor.systemGray2))
                .center()
                // scale in order to better see it, keeping the
                // ratio between the border width and total size
                .scaleEffect(6)
                .navigationTitle(Text(verbatim: "Conversations"))
                .navigationBarTitleDisplayMode(.inline)
                .background(Color(UIColor.systemGray3))
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {} label: {
                            AccountImageViewRepresentable(accountImage, availability)
                                .padding(.horizontal)
                        }
                    }
                }
        }
    }
}

private extension View {

    func center() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                self
                Spacer()
            }
            Spacer()
        }
    }
}
