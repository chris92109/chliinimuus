import SwiftUI

/// Background used by the widget (and its preview in the app):
/// the chosen photo with a dark tint, or the default purple gradient.
struct WidgetBackground: View {
    let image: UIImage?

    var body: some View {
        if let image {
            Color.black.overlay {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .overlay {
                LinearGradient(colors: [.black.opacity(0.15), .black.opacity(0.55)],
                               startPoint: .top, endPoint: .bottom)
            }
        } else {
            LinearGradient(colors: [Color(red: 0.35, green: 0.34, blue: 0.84),
                                    Color(red: 0.62, green: 0.35, blue: 0.85)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
