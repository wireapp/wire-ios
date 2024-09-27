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
import WireUtilities

struct DeveloperE2eiView: View {
    // MARK: Internal

    @StateObject var viewModel: DeveloperE2eiViewModel

    var body: some View {
        List {
            Section("E2EI Certificate Details") {
                HStack {
                    Text("Valid from")
                    Spacer()
                    Text(viewModel.certificateValidFrom)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Valid to")
                    Spacer()
                    Text(viewModel.certificateValidTo)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(.secondary)
                }
            }

            Section("Enroll E2EI Certificate") {
                TextField("Certificate expiration time (in seconds)", text: $viewModel.certificateExpirationTime)

                Button("Enroll", action: { viewModel.enrollCertificate() })
            }

            Section("Certificate Revocation Lists") {
                toggleRow(
                    title: "Force CRL expiry after 1 minute",
                    description: "Sets the CRL expiration time to 1 minute. Enable to force refresh the CRLs when the app comes to the foreground (at least one minute after the CRL has been fetched the 1st time).",
                    binding: binding(for: .forceCRLExpiryAfterOneMinute)
                )
                VStack(alignment: .leading) {
                    Button("Clear CRL expiration dates", action: { viewModel.removeAllExpirationDates() })
                    footNote(
                        "Clears the CRL expiration dates from storage. Will force the CRLs to be refetched when discovering distribution points"
                    )
                }
            }

            Section("CRLs expiration dates") {
                if viewModel.storedCRLExpirationDatesByURL.isEmpty {
                    Text("There are no stored expiration dates")
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

                Button("Refresh", action: { viewModel.refreshCRLExpirationDates() })
            }
        }
    }

    // MARK: Private

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
    DeveloperE2eiView(viewModel: DeveloperE2eiViewModel())
}
