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

import SwiftUI

struct DeveloperE2eiView: View {

    @StateObject var viewModel: DeveloperE2eiViewModel

    var body: some View {

        List {
            Section("E2EI Certificate Details") {
                HStack {
                    Text(String("Valid from"))
                    Spacer()
                    Text(viewModel.certificateValidFrom)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text(String("Valid to"))
                    Spacer()
                    Text(viewModel.certificateValidTo)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(.secondary)
                }

            }

            Section("Enroll E2EI Certificate") {
                Stepper(
                    value: $viewModel.certificateExpirationTime,
                    in: DeveloperE2eiViewModel.minimumCertificateExpirationTime ... Int.max,
                    step: 60
                ) {
                    HStack {
                        Text(String("Expiration time"))
                        Spacer()
                        Text("\(viewModel.certificateExpirationTime) s")
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading) {
                    Button(String("Enroll"), action: { viewModel.enrollCertificate() })
                    footNote(
                        "Starts the enrollment flow with the selected expiration time."
                    )
                }

                VStack(alignment: .leading) {
                    Button(String("Show update certificate alert")) {
                        viewModel.showUpdateCertificateAlert(canRemindLater: false)
                    }
                    footNote(
                        "Manually triggers the \"Update Certificate\" popup. Tapping \"Update Certificate\" in the alert starts the enrollment flow with the selected expiration time."
                    )
                }
            }

            Section("Credentials") {
                VStack(alignment: .leading) {
                    HStack {
                        Button(String("Check credentials")) {
                            viewModel.checkCredentials()
                        }
                        .disabled(viewModel.isCheckingCredentials)

                        if viewModel.isCheckingCredentials {
                            Spacer()
                            ProgressView()
                        }
                    }
                    if !viewModel.credentialsCheckStatus.isEmpty {
                        Text(viewModel.credentialsCheckStatus)
                            .font(.footnote)
                    }
                    footNote(
                        "Asks CoreCrypto to check all credentials, which refetches every relevant certificate revocation list. If your own certificate has been revoked, the revoked certificate alert is shown. The verification status of all MLS conversations is then updated in the background."
                    )
                }
            }
        }
    }

    private func footNote(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.secondary)
    }
}

// MARK: - Previews

#Preview {
    DeveloperE2eiView(viewModel: DeveloperE2eiViewModel(userSession: nil))
}
