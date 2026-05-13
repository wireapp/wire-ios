//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import FLAnimatedImage
import UIKit
import WireCommonComponents
import WireDesign
import Ziphy

protocol GiphyConfirmationViewControllerDelegate: AnyObject {

    func giphyConfirmationViewController(
        _ giphyConfirmationViewController: GiphyConfirmationViewController,
        didConfirmImageData imageData: Data
    )

}

final class GiphyConfirmationViewController: UIViewController {

    private let imagePreview = FLAnimatedImageView()
    private let acceptButton = ZMButton(
        style: .accentColorTextButtonStyle,
        cornerRadius: 16,
        fontSpec: .normalSemiboldFont
    )
    private let cancelButton = ZMButton(
        style: .secondaryTextButtonStyle,
        cornerRadius: 16,
        fontSpec: .normalSemiboldFont
    )
    private let buttonContainer = UIView()
    weak var delegate: GiphyConfirmationViewControllerDelegate?
    private let searchResultController: ZiphySearchResultsController?
    private let ziph: Ziph?
    private var viewModel: GiphyConfirmationViewModel

    /// init method with optional arguments for remove dependency for testing
    ///
    /// - Parameters:
    ///   - ziph: provide nil for testing only
    ///   - previewImage: image for preview
    ///   - searchResultController: provide nil for testing only
    init(
        withZiph ziph: Ziph?,
        previewImage: FLAnimatedImage?,
        searchResultController: ZiphySearchResultsController?
    ) {
        self.ziph = ziph
        self.searchResultController = searchResultController
        self.viewModel = GiphyConfirmationViewModel(canFetchImage: ziph != nil && searchResultController != nil)

        super.init(nibName: nil, bundle: nil)

        if let previewImage {
            imagePreview.animatedImage = previewImage
        }

        let closeItem = UIBarButtonItem.closeButton(action: UIAction { [weak self] _ in
            self?.perform(.closeTapped)
        }, accessibilityLabel: viewModel.displayState.closeAccessibilityLabel)

        navigationItem.rightBarButtonItem = closeItem

        view.backgroundColor = SemanticColors.View.backgroundDefault
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        extendedLayoutIncludesOpaqueBars = true

        let titleLabel = UILabel()
        titleLabel.font = FontSpec.headerSemiboldFont.font!
        titleLabel.textColor = SemanticColors.Label.textDefault
        titleLabel.text = title
        titleLabel.sizeToFit()
        navigationItem.titleView = titleLabel

        view.backgroundColor = .black
        apply(displayState: viewModel.displayState)
        acceptButton.addTarget(self, action: #selector(GiphyConfirmationViewController.onAccept), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(GiphyConfirmationViewController.onCancel), for: .touchUpInside)

        imagePreview.contentMode = .scaleAspectFit

        view.addSubview(imagePreview)
        view.addSubview(buttonContainer)

        [cancelButton, acceptButton].forEach(buttonContainer.addSubview)

        configureConstraints()
        perform(.open)
    }

    private func fetchImage() {
        guard let ziph, let searchResultController else {
            _ = viewModel.effect(for: .imageFetchFailed)
            return
        }

        searchResultController.fetchImageData(for: ziph, imageType: .downsized) { [weak self] result in
            guard let self else { return }

            guard case let .success(imageData) = result else {
                _ = self.viewModel.effect(for: .imageFetchFailed)
                return
            }

            self.imagePreview.animatedImage = FLAnimatedImage(animatedGIFData: imageData)
            _ = self.viewModel.effect(for: .imageFetchSucceeded(imageData))
            self.apply(displayState: self.viewModel.displayState)
        }
    }

    @objc
    private func onDismiss() {
        perform(.closeTapped)
    }

    @objc
    private func onCancel() {
        perform(.cancelTapped)
    }

    @objc
    private func onAccept() {
        perform(.confirmTapped)
    }

    private func perform(_ action: GiphyConfirmationViewModel.Action) {
        switch viewModel.effect(for: action) {
        case .fetchImage:
            fetchImage()
        case .none:
            break
        }

        switch viewModel.route(for: action) {
        case let .confirm(imageData):
            delegate?.giphyConfirmationViewController(self, didConfirmImageData: imageData)
        case .pop:
            _ = navigationController?.popViewController(animated: true)
        case .dismiss:
            presentingViewController?.dismiss(animated: true, completion: nil)
        case .none:
            break
        }
    }

    private func apply(displayState: GiphyConfirmationViewModel.DisplayState) {
        acceptButton.isEnabled = displayState.confirmButton.isEnabled
        acceptButton.setTitle(displayState.confirmButton.title, for: .normal)
        cancelButton.isEnabled = displayState.cancelButton.isEnabled
        cancelButton.setTitle(displayState.cancelButton.title, for: .normal)
    }

    private func configureConstraints() {

        let widthConstraint = buttonContainer.widthAnchor.constraint(equalToConstant: 476)

        widthConstraint.priority = .init(700)

        [
            imagePreview,
            buttonContainer,
            cancelButton,
            acceptButton
        ].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            imagePreview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            imagePreview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            imagePreview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imagePreview.bottomAnchor.constraint(equalTo: buttonContainer.topAnchor, constant: -20),

            cancelButton.heightAnchor.constraint(equalToConstant: 40),
            cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            cancelButton.leftAnchor.constraint(equalTo: buttonContainer.leftAnchor),
            cancelButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),

            acceptButton.heightAnchor.constraint(equalToConstant: 40),
            acceptButton.rightAnchor.constraint(equalTo: buttonContainer.rightAnchor),
            acceptButton.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            acceptButton.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),

            cancelButton.widthAnchor.constraint(equalTo: acceptButton.widthAnchor),
            cancelButton.rightAnchor.constraint(equalTo: acceptButton.leftAnchor, constant: -16),

            buttonContainer.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor, constant: 32),
            buttonContainer.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor, constant: -32),
            buttonContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -32),
            widthConstraint,
            buttonContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
}
