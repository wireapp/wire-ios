//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireFoundation
import WireReusableUIComponents

typealias ExportBackupView = SetExportPasswordView

/// A view that allows to export the backup.

struct SetExportPasswordView: View {

    @Environment(\.dismiss) private var dismiss

    @ObservedObject private(set) var viewModel: SetExportPasswordViewModel

    var body: some View {
        setBackupPasswordView
            .background(Color.viewBackground)
            .scrollContentBackground(.hidden)
            .navigationTitle(Text(L10n.Localizable.ExportBackup.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    CloseButton(
                        action: { dismiss() },
                        accessibilityLabel: L10n.Accessibility.SetBackupPassword.Close.label
                    )
                }
            }
    }

    @ViewBuilder
    private var setBackupPasswordView: some View {
        VStack {
//            let scrollView = ScrollView {
//                VStack(spacing: 20) {
                    Text(L10n.Localizable.ExportBackup.description)
                        .wireTextStyle(.body1)
                        .foregroundStyle(Color.primaryText)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal)

                    PasswordFieldView(
                        password: $viewModel.password,
                        isPasswordVisible: $viewModel.isPasswordVisible,
                        isPasswordValid: viewModel.isPasswordValid,
                        passwordRules: Text(viewModel.localizedPasswordRules)
                    )
                    .background(Color.red)
//                }
//                //                    .frame(maxWidth: .infinity)
//            }
//            if #available(iOS 16.4, *) {
//                scrollView
//                    .scrollBounceBehavior(.basedOnSize)
//            } else {
//                scrollView
//            }

            Spacer()

            Button {
                dismiss()
                viewModel.triggerExport()
            } label: {
                Text(L10n.Localizable.ExportBackup.button)
            }
            .disabled(!viewModel.isPasswordValid)
            .wireButtonStyle(.primary)
            .padding()
        }
        .background(Color.green)
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("uikit") {
    {
        MainViewController()
    }()
}

#Preview("Set Export Backup Password") {
    SetExportPasswordPreview()
}

class SecondViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        // Add a label or any UI elements you need
        let label = UILabel()
        label.text = "This is a sheet! \n \n abd \n \n abd \n \n abd \n \n abd \n \n abd"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)

        // Constraints
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

class MainViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupPresentButton()
    }

    private func setupPresentButton() {
        let button = UIButton(type: .system)
        button.setTitle("Present Sheet", for: .normal)
        button.addTarget(self, action: #selector(presentSheet), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(button)

        // Constraints
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func presentSheet() {
        let sheetVC = SecondViewController()
        sheetVC.modalPresentationStyle = .pageSheet

        if let sheet = sheetVC.sheetPresentationController {
            sheet.detents = [.customHeight(200)]
            sheet.prefersGrabberVisible = true
            sheet.largestUndimmedDetentIdentifier = .medium
            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }
        present(sheetVC, animated: true, completion: nil)
    }
}

extension UISheetPresentationController.Detent {
    static func customHeight(_ height: CGFloat) -> UISheetPresentationController.Detent {
        .custom { context in height }
    }
}
