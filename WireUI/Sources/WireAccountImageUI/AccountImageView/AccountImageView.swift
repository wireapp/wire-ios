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

private let availabilityIndicatorDiameterFraction = CGFloat(10) / 32

// MARK: -

/// Displays the image of a user account plus optional availability.
public final class AccountImageView: UIView {

    // MARK: - Constants

    // Constants relevant for calculating the intrinsic content size
    private let accountImageHeight: CGFloat = 26
    private let teamAccountImageCornerRadius: CGFloat = 6
    private let initialsLabelInset: CGFloat = 5

    enum Defaults {
        static let imageViewBorderWidth: CGFloat = 1
        static let imageViewBorderColor: UIColor = .gray
    }

    // MARK: - Public Properties

    public var source = AccountImageSource() {
        didSet { updateAccountImage() }
    }

    // TODO: [WPB-11449] is this even needed? We always show the user's image
    public var isTeamAccount = false {
        didSet { updateShape() }
    }

    public var availability: Availability? {
        didSet { updateAvailabilityIndicator() }
    }

    public var imageBorderWidth = Defaults.imageViewBorderWidth {
        didSet { updateAccountImageBorder() }
    }

    public var imageBorderColor = Defaults.imageViewBorderColor {
        didSet { updateAccountImageBorder() }
    }

    public var availableColor: UIColor {
        get { availabilityIndicatorView.availableColor }
        set { availabilityIndicatorView.availableColor = newValue }
    }

    public var awayColor: UIColor {
        get { availabilityIndicatorView.awayColor }
        set { availabilityIndicatorView.awayColor = newValue }
    }

    public var busyColor: UIColor {
        get { availabilityIndicatorView.busyColor }
        set { availabilityIndicatorView.busyColor = newValue }
    }

    public var availabilityIndicatorBackgroundColor: UIColor {
        get { availabilityIndicatorView.backgroundViewColor }
        set { availabilityIndicatorView.backgroundViewColor = newValue }
    }

    // MARK: - Private Properties

    private let accountImageView = UIImageView()
    private let initialsLabel = UILabel()
    let availabilityIndicatorView = AvailabilityIndicatorView()

    override public var intrinsicContentSize: CGSize {
        .init(
            width: imageBorderWidth * 2 + accountImageHeight,
            height: imageBorderWidth * 2 + accountImageHeight
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
        NSLayoutConstraint.activate([
            // make sure it's in the center, even if the surrounding view is not a square
            accountImageViewWrapper.centerXAnchor.constraint(equalTo: centerXAnchor),
            accountImageViewWrapper.centerYAnchor.constraint(equalTo: centerYAnchor),
            // aspect ratio 1:1
            accountImageViewWrapper.widthAnchor.constraint(equalTo: accountImageViewWrapper.heightAnchor),
            // ensure the image wrapper is always inside its container
            accountImageViewWrapper.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            accountImageViewWrapper.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            trailingAnchor.constraint(greaterThanOrEqualTo: accountImageViewWrapper.trailingAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: accountImageViewWrapper.bottomAnchor)
        ])
        // enlarge the image wrapper as much as possible
        NSLayoutConstraint.activate([
            accountImageViewWrapper.leadingAnchor.constraint(equalTo: leadingAnchor),
            accountImageViewWrapper.topAnchor.constraint(equalTo: topAnchor),
            trailingAnchor.constraint(equalTo: accountImageViewWrapper.trailingAnchor),
            bottomAnchor.constraint(equalTo: accountImageViewWrapper.bottomAnchor)
        ].map { constraint in
            // lower priority
            constraint.priority = .defaultHigh
            return constraint
        })

        // the image view which displays the account image
        accountImageView.contentMode = .scaleAspectFill
        accountImageView.translatesAutoresizingMaskIntoConstraints = false
        accountImageViewWrapper.addSubview(accountImageView)
        NSLayoutConstraint.activate([
            accountImageView.widthAnchor.constraint(equalToConstant: accountImageHeight),
            accountImageView.heightAnchor.constraint(equalToConstant: accountImageHeight)
        ].map { constraint in
            // fallback, lower priority
            constraint.priority = .defaultLow
            return constraint
        })

        initialsLabel.font = .systemFont(ofSize: 100, weight: .light)
        initialsLabel.textAlignment = .center
        initialsLabel.adjustsFontSizeToFitWidth = true
        initialsLabel.minimumScaleFactor = 0.1
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        accountImageViewWrapper.addSubview(initialsLabel)

        NSLayoutConstraint.activate([
            // image mode
            accountImageView.leadingAnchor.constraint(equalTo: accountImageViewWrapper.leadingAnchor, constant: imageBorderWidth),
            accountImageView.topAnchor.constraint(equalTo: accountImageViewWrapper.topAnchor, constant: imageBorderWidth),
            accountImageViewWrapper.trailingAnchor.constraint(equalTo: accountImageView.trailingAnchor, constant: imageBorderWidth),
            accountImageViewWrapper.bottomAnchor.constraint(equalTo: accountImageView.bottomAnchor, constant: imageBorderWidth),
            // text mode
            initialsLabel.leadingAnchor.constraint(equalTo: accountImageViewWrapper.leadingAnchor, constant: initialsLabelInset),
            initialsLabel.topAnchor.constraint(equalTo: accountImageViewWrapper.topAnchor, constant: initialsLabelInset),
            accountImageViewWrapper.trailingAnchor.constraint(equalTo: initialsLabel.trailingAnchor, constant: initialsLabelInset),
            accountImageViewWrapper.bottomAnchor.constraint(equalTo: initialsLabel.bottomAnchor, constant: initialsLabelInset)
        ])

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

        accountImageViewWrapper.layer.borderWidth = imageBorderWidth
        accountImageViewWrapper.layer.borderColor = imageBorderColor.cgColor
    }

    private func updateAccountImage() {
        switch source {
        case .data(let data):
            initialsLabel.text = nil
            accountImageView.image = UIImage(data: data)
        case .text(let initials):
            initialsLabel.text = initials
            accountImageView.image = nil
        }
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

// TODO: is this used?
public extension AccountImageView {

    convenience init(
        accountImage: UIImage,
        isTeamAccount: Bool,
        availability: Availability?
    ) {
        self.init()

        self.source = .data(accountImage.pngData() ?? .init())
        self.isTeamAccount = isTeamAccount
        self.availability = availability

        updateAccountImage()
        updateShape()
        updateAvailabilityIndicator()
    }
}

// MARK: - Previews

struct AccountImageView_Previews: PreviewProvider {

    static let accountImage = UIImage.from(solidColor: .init(red: 0, green: 0.73, blue: 0.87, alpha: 1))
    static let initials = "CA"

    static var previews: some View {
        Group {
            previewWithNavigationBar(.data(accountImage.pngData()!), .none)
                .previewDisplayName("image")
            previewWithNavigationBar(.text(initials: initials), .none)
                .previewDisplayName("text")

            ForEach(Availability.allCases, id: \.self) { availability in
                previewWithNavigationBar(.data(accountImage.pngData()!), availability)
                    .previewDisplayName("image \(availability)")
                previewWithNavigationBar(.text(initials: initials), availability)
                    .previewDisplayName("text \(availability)")
            }
        }
    }

    @ViewBuilder
    static func previewWithNavigationBar(
        _ source: AccountImageSource,
        _ availability: Availability?
    ) -> some View {
        NavigationStack {
            AccountImageViewRepresentable(source, availability)
                // slightly differnet colors so that we can verify that the view modifiers work
                .accountImageViewBorderColor(.init(red: 0.56, green: 0.56, blue: 0.56, alpha: 1.00))
                .availabilityIndicatorAvailableColor(.init(red: 0.01, green: 0.99, blue: 0.66, alpha: 1))
                .availabilityIndicatorAwayColor(.init(red: 0.7, green: 0.15, blue: 0.07, alpha: 1))
                .availabilityIndicatorBusyColor(.init(red: 0.42, green: 0.19, blue: 0.1, alpha: 1))
                .availabilityIndicatorBackgroundViewColor(.init(red: 0.83, green: 0.81, blue: 0.8, alpha: 1))
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
                            AccountImageViewRepresentable(source, availability)
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
