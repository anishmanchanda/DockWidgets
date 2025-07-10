import SwiftUI
import Combine

class FlipClockWidget: BaseWidget {
    @Published var currentTime: String = ""
    private var timer: AnyCancellable?
    
    override init(position: CGPoint, size: CGSize = CGSize(width: 300, height: 80)) {
        super.init(position: position, size: size)
        startTimer()
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTime()
            }
    }
    
    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        currentTime = formatter.string(from: Date())
    }
    
    override func createView() -> AnyView {
        AnyView(FlipClockView(widget: self))
    }
}

struct FlipClockView: View {
    @ObservedObject var widget: FlipClockWidget
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(widget.currentTime.enumerated()), id: \.offset) { index, character in
                if character == ":" {
                    Text(":")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                } else {
                    FlipDigitView(character: String(character))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
    }
}

struct FlipDigitView: View {
    let character: String
    @State private var isFlipping = false
    @State private var previousCharacter: String = ""
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.8))
                .frame(width: 40, height: 60)
            
            // Flip animation
            Text(character)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .rotation3DEffect(
                    .degrees(isFlipping ? 180 : 0),
                    axis: (x: 1, y: 0, z: 0)
                )
                .animation(.easeInOut(duration: 0.3), value: isFlipping)
        }
        .onChange(of: character) { newValue in
            if newValue != previousCharacter {
                withAnimation {
                    isFlipping = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation {
                        isFlipping = false
                    }
                }
                previousCharacter = newValue
            }
        }
    }
}