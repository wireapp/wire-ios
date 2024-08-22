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
            accountImageHeight / 2 + accountImageBorderWidth
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
            ForEach([false, true], id: \.self) { isTeamAccount in

                previewWithNavigationBar(isTeamAccount, .none)
                    .previewDisplayName(isTeamAccount ? "team" : "personal")

                ForEach(Availability.allCases, id: \.self) { availability in
                    previewWithNavigationBar(isTeamAccount, availability)
                        .previewDisplayName(isTeamAccount ? "team" : "personal" + " - \(availability)")
                }
            }
        }
    }

    @ViewBuilder
    static func previewWithNavigationBar(
        _ isTeamAccount: Bool,
        _ availability: Availability?
    ) -> some View {
        let accountImage = UIImage.from(solidColor: .init(red: 0, green: 0.73, blue: 0.87, alpha: 1))
        NavigationStack {
            AccountImageViewRepresentable(accountImage, isTeamAccount, availability)
                .center()
                .scaleEffect(6)
                .navigationTitle("Conversations")
                .navigationBarTitleDisplayMode(.inline)
                .background(Color(UIColor.systemGray2))
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {} label: {
                            AccountImageViewRepresentable(accountImage, isTeamAccount, availability)
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

private extension AccountImageViewRepresentable {

    init(
        _ accountImage: UIImage,
        _ isTeamAccount: Bool,
        _ availability: Availability?
    ) {
        self.init(
            accountImage: accountImage,
            isTeamAccount: isTeamAccount,
            availability: availability
        )
    }
}

private extension UIImage {

    static func from(solidColor color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: .init(width: 1, height: 1)).image { rendererContext in
            color.setFill()
            rendererContext.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
}
