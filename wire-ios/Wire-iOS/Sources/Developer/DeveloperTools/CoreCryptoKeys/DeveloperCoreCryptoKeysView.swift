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

// MARK: - Views

struct DeveloperCoreCryptoKeysView: View {
    @StateObject var viewModel: DeveloperCoreCryptoKeysViewModel

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.accounts, id: \.userID) { account in
                    Section(header: Text(viewModel.nameText(for: account))) {
                        if !account.keys.isEmpty {
                            keysSection(keys: account.keys)
                        }
                        uniqueKeyIdSection(uuid: account.uniqueKeyID)
                    }
                }
            }
            .navigationTitle("Core Crypto Keys")
        }
    }

    func keysSection(keys: [KeychainItem]) -> some View {
        Section(header: Text("Keychain Items").font(.headline)) {
            ForEach(keys) { item in
                Text(item.applicationTag ?? "<no tag>")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .swipeActions {
                        Button(role: .destructive) {
                            viewModel.deleteKeychainItem(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    func uniqueKeyIdSection(uuid: UUID?) -> some View {
        Section(header: Text("Unique Key Identifier").font(.headline)) {
            if let uuid {
                Text(uuid.uuidString)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                Text("No UUID stored")
                    .foregroundColor(.gray)
            }
        }
    }
}
