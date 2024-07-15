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

private let accountImageViewBorderColor = ColorTheme.Strokes.outline
private let availabilityIndicatorBackgroundColor = UIColor {
    $0.userInterfaceStyle == .dark
        ? BaseColorPalette.Grays.gray90
        : .clear
}

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

    public var isTeamAccount = false {
        didSet { updateShape() }
    }

    public var availability: Availability? {
        didSet { updateAvailabilityIndicator() }
    }

    // MARK: - Private Properties

    private let accountImageView = UIImageView()
    private let availabilityIndicatorView = AvailabilityIndicatorView()
    // provides a background color only for dark mode
    private let availabilityIndicatorBackgroundView = UIView()

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
            availabilityIndicatorView.widthAnchor.constraint(equalToConstant: availabilityIndicatorRadius * 2),
            availabilityIndicatorView.heightAnchor.constraint(equalToConstant: availabilityIndicatorRadius * 2),
            accountImageViewWrapper.trailingAnchor.constraint(equalTo: availabilityIndicatorView.trailingAnchor),
            accountImageViewWrapper.bottomAnchor.constraint(equalTo: availabilityIndicatorView.bottomAnchor)
        ])

        // background view for the availability indicator
        availabilityIndicatorBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(availabilityIndicatorBackgroundView, belowSubview: availabilityIndicatorView)
        NSLayoutConstraint.activate([
            availabilityIndicatorView.leadingAnchor.constraint(equalTo: availabilityIndicatorBackgroundView.leadingAnchor, constant: availabilityIndicatorBorderWidth),
            availabilityIndicatorView.topAnchor.constraint(equalTo: availabilityIndicatorBackgroundView.topAnchor, constant: availabilityIndicatorBorderWidth),
            availabilityIndicatorBackgroundView.trailingAnchor.constraint(equalTo: availabilityIndicatorView.trailingAnchor, constant: availabilityIndicatorBorderWidth),
            availabilityIndicatorBackgroundView.bottomAnchor.constraint(equalTo: availabilityIndicatorView.bottomAnchor, constant: availabilityIndicatorBorderWidth)
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

        // update the background view of the activitiy indicator view
        availabilityIndicatorBackgroundView.layer.cornerRadius = availabilityIndicatorBackgroundView.frame.height / 2
        availabilityIndicatorBackgroundView.backgroundColor = availabilityIndicatorBackgroundColor
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

        // for dark mode
        availabilityIndicatorBackgroundView.isHidden = availability == .none || traitCollection.userInterfaceStyle != .dark

        if availability == .none || traitCollection.userInterfaceStyle == .dark {
            // remove clipping
            accountImageView.superview?.layer.mask = .none
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

        // this clips a circle from the view, which gives the
        // availability indicator view a transparent border
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        maskLayer.fillRule = .evenOdd
        accountImageView.superview?.layer.mask = maskLayer
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
        .background(Color(UIColor.systemGray2))
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

private struct AccountImageViewRepresentable: UIViewRepresentable {

    private(set) var accountImage: UIImage
    private(set) var isTeamAccount: Bool
    private(set) var availability: Availability?

    init(
        _ accountImage: UIImage,
        _ isTeamAccount: Bool,
        _ availability: Availability?
    ) {
        self.accountImage = accountImage
        self.isTeamAccount = isTeamAccount
        self.availability = availability
    }

    func makeUIView(context: Context) -> AccountImageView {
        .init()
    }

    func updateUIView(_ view: AccountImageView, context: Context) {
        view.accountImage = accountImage
        view.isTeamAccount = isTeamAccount
        view.availability = availability
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
