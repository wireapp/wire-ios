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
import WireUtilities

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

            Section("Certificate Revocation Lists") {
                footNote(
                    "a Certificate Revocation List (CRL) lists all the certificates that have been revoked for a given domain. They have an expiration time, after which they will be refetched."
                )

                toggleRow(
                    title: "Force CRL expiry after 1 minute",
                    description: "Sets the CRL expiration time to 1 minute. Enable to force refresh the CRLs when the app comes to the foreground (at least one minute after the CRL has been fetched the 1st time). -  Best to enable before login.",
                    binding: binding(for: .forceCRLExpiryAfterOneMinute)
                )
                VStack(alignment: .leading) {
                    Button(String("Clear CRL expiration dates"), action: { viewModel.removeAllExpirationDates() })
                    footNote(
                        "Clears the CRL expiration dates from storage. Will force the CRLs to be refetched when discovering distribution points"
                    )
                }
            }

            Section("CRLs expiration dates") {

                footNote(
                    "A CRL (Certificate Revocation List) has an expiration date. When the date is reached, the CRL will be refetched."
                )

                if viewModel.storedCRLExpirationDatesByURL.isEmpty {
                    Text(String("There are no stored expiration dates"))
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(viewModel.storedCRLExpirationDatesByURL.keys), id: \.self) { url in
                        VStack(alignment: .leading) {
                            Text(url)
                            Text(viewModel.storedCRLExpirationDatesByURL[url] ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Button(String("Refresh"), action: { viewModel.refreshCRLExpirationDates() })
            }
        }
    }

    private func toggleRow(
        title: String,
        description: String,
        binding: Binding<Bool>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(title, isOn: binding)
            footNote(description)
        }
    }

    private func footNote(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.secondary)
    }

    private func binding(for flag: DeveloperFlag) -> Binding<Bool> {
        var flag = flag
        return Binding(
            get: { flag.isOn },
            set: { flag.isOn = $0 }
        )
    }
}

// MARK: - Previews

#Preview {
    DeveloperE2eiView(viewModel: DeveloperE2eiViewModel(userSession: nil))
}
