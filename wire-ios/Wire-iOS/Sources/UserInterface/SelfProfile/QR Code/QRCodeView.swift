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
    @ObservedObject var viewModel: UserQRCodeViewModel

    var body: some View {
        VStack {
            Spacer()
            VStack {
                // QR Code with logo
                ZStack {
                    VStack {
                        Image(uiImage: QRCodeGenerator.generateQRCode(from: viewModel.profileLink))
                            .interpolation(.none)
                            .resizable()
                            .frame(width: 250, height: 250)
                    }
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text("W")
                                .foregroundColor(.white)
                                .font(.system(size: 30, weight: .bold))
                        )
                }
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)

                VStack(spacing: 5) {
                    Text("")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(0)
                        .truncationMode(.middle)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .cornerRadius(12)

            Spacer()

            // Informational text
            Text("Share your profile to connect easily with other people. You must still accept a connection request before you two can start communicating.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.gray)

            // Share buttons
            Button(action: {
                // Implement share link action
            }) {
                Text("Share Link")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button(action: {
                // Implement share QR code action
            }) {
                HStack {
                    Image(systemName: "qrcode")
                    Text("Share QR Code")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow)
                .foregroundColor(.black)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Share Profile", displayMode: .inline)
        .navigationBarItems(leading: Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .imageScale(.large)
        })
    }
}
