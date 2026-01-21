import SwiftUI
import WireDesign

struct CreateFolderCTA: View {

    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            Button(action: action) {
                HStack(alignment: .center, spacing: 20) {
                    Image(systemName: "plus")

                    Text(L10n.Localizable.Conversation.WireCells.Files.List.newFolder)
                        .font(for: .body2)
                    Spacer()
                }
            }
            .tint(ColorTheme.Backgrounds.onSurface.color)
            .padding()
        }
        .contentShape(Rectangle())
    }
}