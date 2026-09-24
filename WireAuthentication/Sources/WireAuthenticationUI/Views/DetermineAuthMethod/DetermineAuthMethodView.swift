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

#if DEBUG
    import AVFoundation
#endif
import SwiftUI
#if DEBUG
    import UIKit
#endif
import WireAuthenticationAPI
import WireDesign
import WireLocators
import WireNetwork
import WireReusableUIComponents

package protocol DetermineAuthMethodFactory {

    @MainActor var viewModel: DetermineAuthMethodViewModel { get }

    @MainActor
    func loginView(
        email: String?,
        didDetectDomainConflict: Bool,
        environment: BackendEnvironment2
    ) -> LoginViaEmailView

    @MainActor
    func loginOrRegisterView(
        email: String?,
        didDetectDomainConflict: Bool,
        environment: BackendEnvironment2
    ) -> LoginViaEmailView

    @MainActor
    func noHistoryView(result: AuthenticationResult) -> NoHistoryView

}

package struct DetermineAuthMethodView: View {

    @StateObject var viewModel: DetermineAuthMethodViewModel
    #if DEBUG
        @State private var isQRCodeScannerPresented = false
    #endif

    private typealias Strings = L10n.Localizable.Authentication

    package init(factory: @autoclosure @escaping () -> any DetermineAuthMethodFactory) {
        self._viewModel = StateObject(wrappedValue: factory().viewModel)
    }

    package var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 16) {
                header
                message
                inputField
                submitButton
            }
            .padding()
            .setPreferredSize(navigationBarHidden: !viewModel.existsAnotherAccount)
        }
        .toolbar {
            if viewModel.existsAnotherAccount {
                ToolbarItem(placement: .topBarTrailing) {
                    dismissButton
                }
            }
        }
        .alert(
            item: $viewModel.alert,
            title: { Text($0.title) },
            message: { Text($0.message) },
            actions: { _ in
                Button(Strings.Error.confirm, action: viewModel.onAlertDismiss)
            }
        )
        .navigationDestination(for: DetermineAuthMethodDestination.self) {
            destinationView(for: $0)
        }
        .fullScreenCover(item: $viewModel.modalDestination, onDismiss: viewModel.onModalDismissed) {
            sheetView(for: $0)
                .presentationBackground(Color.black.opacity(0.7))
        }
        #if DEBUG
        .sheet(isPresented: $isQRCodeScannerPresented) {
                DeveloperCredentialQRCodeScannerView { scannedCode in
                    isQRCodeScannerPresented = false
                    viewModel.submitDeveloperCredentialQRCode(scannedCode)
                }
            }
        #endif
            .interactiveDismissDisabled()
            .background(ColorTheme.Backgrounds.surface.color)
            .presentationDragIndicator(.hidden)
    }

    // MARK: - Views

    @ViewBuilder private var header: some View {
        Group {
            if viewModel.isOnPremiseBackend {
                OnPremHeaderView(environment: viewModel.environment)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                Logo().frame(width: 164, height: 95)
            }
        }
        .foregroundColor(ColorTheme.Backgrounds.onBackground.color)
    }

    @ViewBuilder private var message: some View {
        Text(Strings.Identity.Input.body)
            .multilineTextAlignment(.center)
            .font(for: .body1)
            .accessibilityHeading(.h1)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.trailing)
    }

    @ViewBuilder private var inputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            #if DEBUG
                ZStack(alignment: .bottomTrailing) {
                    inputTextField

                    if viewModel.isOnPremiseBackend {
                        Button {
                            isQRCodeScannerPresented = true
                        } label: {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 22, weight: .medium))
                                .frame(width: 44, height: 44)
                                .padding(.trailing, 4)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Scan credentials QR code")
                    }
                }
            #else
                inputTextField
            #endif
        }
    }

    private var inputTextField: some View {
        LabeledTextField(
            isMandatory: false,
            placeholder: inputFieldPlaceholder,
            title: inputFieldTitle,
            string: $viewModel.emailOrSSOCode,
            keyboardType: .emailAddress,
            textContentType: .username
        )
        .autocorrectionDisabled()
        .lineLimit(nil)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier(Locators.WelcomePage.emailTextField.rawValue)
    }

    private var inputFieldTitle: String {
        if viewModel.overrideAllowEmailLoginOnly {
            Strings.Identity.Input.Field.EmailOnly.title
        } else {
            Strings.Identity.Input.Field.title
        }
    }

    private var inputFieldPlaceholder: String {
        if viewModel.overrideAllowEmailLoginOnly {
            Strings.Identity.Input.Field.EmailOnly.placeholder
        } else {
            Strings.Identity.Input.Field.placeholder
        }
    }

    @ViewBuilder private var submitButton: some View {
        Button(action: {
            Task {
                await viewModel.submitEmailOrSSOCode()
            }
        }, label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                }

                Text(Strings.Identity.Input.submit)
                    .lineLimit(nil)
            }
        })
        .wireButtonStyle(.primary)
        .disabled(!viewModel.isNextButtonEnabled || viewModel.isLoading)
        .accessibilityIdentifier(Locators.WelcomePage.nextButton.rawValue)
    }

    @ViewBuilder private var dismissButton: some View {
        Button {
            viewModel.exitFlow()
        } label: {
            Image(systemName: "xmark")
        }
    }

    // MARK: - Destinations

    @ViewBuilder
    private func destinationView(for destination: DetermineAuthMethodDestination) -> some View {
        switch destination {
        case let .login(email, didDetectDomainConflict, environment):
            viewModel.factory
                .loginView(
                    email: email,
                    didDetectDomainConflict: didDetectDomainConflict,
                    environment: environment
                )
        case let .loginOrRegister(
            email,
            didDetectDomainConflict,
            environment
        ):
            viewModel.factory
                .loginOrRegisterView(
                    email: email,
                    didDetectDomainConflict: didDetectDomainConflict,
                    environment: environment
                )
        case let .noHistory(authenticationResult):
            viewModel.factory.noHistoryView(result: authenticationResult)
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: DetermineAuthMethodSheet) -> some View {
        switch sheet {
        case let .switchBackendConfirmation(
            email,
            environment
        ):
            SwitchBackendConfirmation(environment: environment) { didConfirm in
                viewModel.confirmBackendSwitch(
                    didConfirm: didConfirm,
                    email: email,
                    environment: environment
                )
            }
        }
    }
}

#if DEBUG
    private struct DeveloperCredentialQRCodeScannerView: UIViewControllerRepresentable {
        let onQRCodeScanned: (String) -> Void

        func makeUIViewController(context: Context) -> DeveloperCredentialQRCodeScannerViewController {
            let viewController = DeveloperCredentialQRCodeScannerViewController()
            viewController.onQRCodeScanned = onQRCodeScanned
            return viewController
        }

        func updateUIViewController(
            _ uiViewController: DeveloperCredentialQRCodeScannerViewController,
            context: Context
        ) {}
    }

    private final class DeveloperCredentialQRCodeScannerViewController: UIViewController,
        AVCaptureMetadataOutputObjectsDelegate {
        private var captureSession: AVCaptureSession?
        private var previewLayer: AVCaptureVideoPreviewLayer?
        var onQRCodeScanned: ((String) -> Void)?

        override func viewDidLoad() {
            super.viewDidLoad()

            let captureSession = AVCaptureSession()
            self.captureSession = captureSession

            guard
                let videoCaptureDevice = AVCaptureDevice.default(for: .video),
                let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
                captureSession.canAddInput(videoInput)
            else {
                return
            }

            captureSession.addInput(videoInput)

            let metadataOutput = AVCaptureMetadataOutput()
            guard captureSession.canAddOutput(metadataOutput) else {
                return
            }

            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]

            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer

            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            previewLayer?.frame = view.bounds
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            captureSession?.stopRunning()
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            captureSession?.stopRunning()

            guard
                let readableObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                let stringValue = readableObject.stringValue
            else {
                return
            }

            onQRCodeScanned?(stringValue)
        }
    }
#endif
