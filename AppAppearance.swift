import SwiftUI

struct AppBackgroundView: View {
    @AppStorage("selectedBackground") private var selectedBackground: String = "system"

    var body: some View {
        Group {
            switch selectedBackground {
            case "gradient":
                LinearGradient(
                    colors: [Color(red: 255/255, green: 204/255, blue: 0/255),
                             Color(red: 0/255, green: 51/255, blue: 102/255)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case "midnight":
                Color.blue.opacity(0.2)
            default:
                Color(.systemBackground)
            }
        }
        .ignoresSafeArea()
    }
}

struct AppPreferredScheme: ViewModifier {
    @AppStorage("selectedBackground") private var selectedBackground: String = "system"

    func body(content: Content) -> some View {
        let scheme: ColorScheme? = {
            switch selectedBackground {
            case "midnight", "gradient":
                return .dark
            default:
                return nil
            }
        }()
        return content.preferredColorScheme(scheme)
    }
}

extension View {
    func appPreferredScheme() -> some View { self.modifier(AppPreferredScheme()) }
}

struct AppBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Hello, World!")
                .padding()
        }
        .background(AppBackgroundView())
        .appPreferredScheme()
    }
}
