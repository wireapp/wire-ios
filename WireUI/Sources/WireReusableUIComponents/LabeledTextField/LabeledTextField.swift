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
import WireDesign
import WireFoundation

public struct LabeledTextField: View {

    private let isMandatory: Bool
    private let placeholder: String?
    private let title: String?

    @Binding private var string: String

    public init(mandatory: Bool = false, placeholder: String?, title: String?, string: Binding<String>) {
        self.isMandatory = mandatory
        self.placeholder = placeholder
        self.title = title
        self._string = string
    }

    public var body: some View {
        VStack(alignment: .leading) {
            if let title {
                (
                    isMandatory ? (
                        Text(title) +
                        Text(verbatim: " *")
                            .foregroundColor(ColorTheme.Base.requiredField.color)
                    ) : Text(title)
                )
                .wireTextStyle(.h4)
            }
            TextField(placeholder ?? "", text: $string)
                .textFieldStyle(.roundedBorder)
                .wireTextStyle(.body1)
        }
    }
}

#Preview {
    LabeledTextField(
        mandatory: false,
        placeholder: nil,
        title: nil,
        string: .constant("")
    )
    LabeledTextField(
        mandatory: false,
        placeholder: "Placeholder",
        title: "Some Title",
        string: .constant("")
    )
    LabeledTextField(
        mandatory: true,
        placeholder: "Placeholder",
        title: "Some Title",
        string: .constant("")
    )
    LabeledTextField(
        mandatory: true,
        placeholder: "Placeholder",
        title: "Some Title",
        string: .constant("Lorem ipsum sic amet [...]")
    )
}
