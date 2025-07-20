import SwiftUI
import Combine

class FlipClockWidget: BaseWidget {
    @Published var currentTime: String = ""
    private var timer: AnyCancellable?
    private let settings = UserSettings.shared
    private var settingsSubscription: AnyCancellable?
    
    override init(position: CGPoint, size: CGSize = CGSize(width: 160, height: 50)) {
        super.init(position: position, size: size)
        print("🕰️ FlipClockWidget initialized at position \(position) with size \(size)")
        startTimer()
        setupSettingsObserver()
        updateTime()  // Initial time update
    }
    
    private func setupSettingsObserver() {
        // Disable settings observer to prevent repositioning
        // settingsSubscription = NotificationCenter.default.publisher(for: .settingsChanged)
        //     .sink { [weak self] _ in
        //         self?.updateTime()
        //     }
        print("🕰️ FlipClockWidget: Settings observer disabled for stability")
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
        formatter.dateFormat = settings.getDateFormat()
        currentTime = formatter.string(from: Date())
        print("⏰ Clock updated: \(currentTime)")
    }
    
    override func createView() -> AnyView {
        AnyView(FlipClockView(widget: self))
    }
}

struct FlipClockView: View {
    @ObservedObject var widget: FlipClockWidget
    @ObservedObject private var settings = UserSettings.shared
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(widget.currentTime.enumerated()), id: \.offset) { index, character in
                if character == ":" {
                    Text(":")
                        .font(.system(size: getFontSize(), weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 2, x: 0, y: 0)  // Add shadow for better readability
                } else {
                    FlipDigitView(character: String(character))
                }
            }
        }
        .padding(6)
        .opacity(settings.widgetOpacity)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.clear)  // Completely transparent background
        )
        
        .onAppear {
            print("🕰️ FlipClockView appeared with time: \(widget.currentTime)")
        }
    }
    
    private func getFontSize() -> CGFloat {
        // Scale font size based on widget height - increased base size
        let baseSize: CGFloat = 20  // Increased from 16 to 20
        let scaleFactor = widget.size.height / 40  // 40 is our base height
        return max(baseSize * scaleFactor, 16)  // Minimum 16pt font
    }
}

struct FlipDigitView: View {
    let character: String
    @State private var isFlipping = false
    @State private var previousCharacter: String = ""
    @ObservedObject private var settings = UserSettings.shared
    
    var body: some View {
        ZStack {
            // Background - completely transparent
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.clear)
                .frame(width: 22, height: 30)  // Increased size for larger font
            
            // Flip animation
            Text(character)
                .font(.system(size: getFontSize(), weight: .bold, design: .default))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2, x: 0, y: 0)  // Enhanced shadow for better readability
                .rotation3DEffect(
                    .degrees(isFlipping ? 180 : 0),
                    axis: (x: 1, y: 0, z: 0)
                )
                .animation(.easeInOut(duration: 0.3), value: isFlipping)
        }
        .onChange(of: character) { oldValue, newValue in
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
    
    private func getFontSize() -> CGFloat {
        // Scale font size based on available space - increased base size
        return 20  // Increased base font size from 16 to 20
    }
}
