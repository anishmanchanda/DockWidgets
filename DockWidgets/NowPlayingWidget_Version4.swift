import SwiftUI

class NowPlayingWidget: BaseWidget {
    override init(position: CGPoint, size: CGSize = CGSize(width: 320, height: 80)) {
        super.init(position: position, size: size)
    }
    
    override func createView() -> AnyView {
        AnyView(NowPlayingView())
    }
}

struct NowPlayingView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("No music playing")
                .font(.headline)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(Color.clear) // Completely transparent background
        .cornerRadius(8)
    }
}
