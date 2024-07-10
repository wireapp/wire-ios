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

struct QRCodeView: View {

    @Environment(\.presentationMode) var presentationMode
    @State private var isShareTextSheetPresented = false
    @State private var isShareImageSheetPresented = false
    @ObservedObject var viewModel: UserQRCodeViewModel

    var body: some View {
        VStack {
            VStack(spacing: 20) {
                ZStack {
                    Image(uiImage: viewModel.profileLinkQRCode)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 250, height: 250)
                        .padding(.top, 24)
                }

                VStack(spacing: 4) {
                    Text(viewModel.handle)
                        .font(.textStyle(.h2))
                        .foregroundColor(.black)
                    Text(viewModel.profileLink)
                        .font(.textStyle(.subline1))
                        .foregroundColor(.black)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                }
            }
            .background(Color.white)
            .cornerRadius(20)

            // Informational text
            Text("Share your profile to connect easily with other people. You must still accept a connection request before you two can start communicating.")
                .font(.textStyle(.body1))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(Color.secondaryText)

            Spacer()

            // Share buttons
            Button(action: {
                isShareTextSheetPresented = true
            }) {
                Text("Share Link")
                    .font(.textStyle(.buttonBig))
            }
            .buttonStyle(SecondaryButtonStyle())
            .sheet(isPresented: $isShareTextSheetPresented) {
                ShareSheet(activityItems: [viewModel.profileLink])
            }
            Button(action: {
                isShareImageSheetPresented = true
            }) {
                    Text("Share QR Code")
                        .font(.textStyle(.buttonBig))

            }
            .buttonStyle(SecondaryButtonStyle())
            .sheet(isPresented: $isShareImageSheetPresented) {
                ShareSheet(activityItems: [viewModel.profileLinkQRCode])
            }

        }
        .padding()
        .background(Color.primaryViewBackground.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Share Profile", displayMode: .inline)
        .navigationBarItems(leading: Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .imageScale(.large)
                .foregroundStyle(Color.primaryText)
        })

    }
}

#Preview {
    NavigationView {
        QRCodeView(viewModel: UserQRCodeViewModel(
            profileLink: "http://link,knfieoqrngorengoejnbgjroqekgnbojqre3bgqjore3bgn3ejjeqrlw3bglrejkbgnjorqwbglejrqg",
            accentColor: .blue,
            handle: "handle"))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}
