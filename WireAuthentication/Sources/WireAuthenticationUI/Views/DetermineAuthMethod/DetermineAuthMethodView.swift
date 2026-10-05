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
        private let sessionQueue = DispatchQueue(label: "DeveloperCredentialQRCodeScanner.session")
        private var didScanQRCode = false
        var onQRCodeScanned: ((String) -> Void)?

        override func viewDidLoad() {
            super.viewDidLoad()
            requestCameraAccess()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            previewLayer?.frame = view.bounds
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            stopCaptureSession()
        }

        private func requestCameraAccess() {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                configureCaptureSession()
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                    DispatchQueue.main.async {
                        guard let self else { return }

                        if isGranted {
                            self.configureCaptureSession()
                        } else {
                            self.showScannerError(
                                title: "Camera access needed",
                                message: "Allow camera access to scan credential QR codes."
                            )
                        }
                    }
                }
            default:
                showScannerError(
                    title: "Camera access needed",
                    message: "Allow camera access to scan credential QR codes."
                )
            }
        }

        private func configureCaptureSession() {
            let captureSession = AVCaptureSession()
            self.captureSession = captureSession

            guard
                let videoCaptureDevice = AVCaptureDevice.default(for: .video),
                let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
                captureSession.canAddInput(videoInput)
            else {
                showScannerError(
                    title: "QR scanner unavailable",
                    message: "Could not start the camera."
                )
                return
            }

            captureSession.addInput(videoInput)

            let metadataOutput = AVCaptureMetadataOutput()
            guard captureSession.canAddOutput(metadataOutput) else {
                showScannerError(
                    title: "QR scanner unavailable",
                    message: "Could not read QR codes from the camera."
                )
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

            startCaptureSession()
        }

        private func startCaptureSession() {
            guard let captureSession else { return }

            sessionQueue.async {
                guard !captureSession.isRunning else { return }
                captureSession.startRunning()
            }
        }

        private func stopCaptureSession() {
            guard let captureSession else { return }

            sessionQueue.async {
                guard captureSession.isRunning else { return }
                captureSession.stopRunning()
            }
        }

        private func showScannerError(title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                self?.dismiss(animated: true)
            })
            present(alert, animated: true)
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard !didScanQRCode else { return }

            guard
                let readableObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                let stringValue = readableObject.stringValue
            else {
                return
            }

            didScanQRCode = true
            stopCaptureSession()
            onQRCodeScanned?(stringValue)
        }
    }
#endif
