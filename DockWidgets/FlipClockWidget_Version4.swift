import SwiftUI
import Combine

class FlipClockWidget: BaseWidget {
    @Published var currentTime: String = ""
    private var timer: AnyCancellable?
    private let settings = UserSettings.shared
    private var settingsSubscription: AnyCancellable?
    
    override init(position: CGPoint, size: CGSize = CGSize(width: 180, height: 55)) {
        super.init(position: position, size: size)
        //print("🕰️ FlipClockWidget initialized at position \(position) with size \(size)")
        startTimer()
        setupSettingsObserver()
        updateTime()
    }
    
    private func setupSettingsObserver() {
        settingsSubscription = NotificationCenter.default.publisher(for: .settingsChanged)
            .sink { [weak self] _ in
                self?.updateTime()
            }
        //print("🕰️ FlipClockWidget: Settings observer enabled")
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
        //print("⏰ Clock updated: \(currentTime)")
    }
    
    override func createView() -> AnyView {
        AnyView(FlipClockView(widget: self))
    }
}

struct FlipClockView: View {
    @ObservedObject var widget: FlipClockWidget
    @ObservedObject private var settings = UserSettings.shared
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(widget.currentTime.enumerated()), id: \.offset) { index, character in
                if character == ":" {
                    ColonView()
                } else if character == " " {
                    Spacer()
                        .frame(width: 6)
                } else {
                    FlipCard(character: String(character))
                }
            }
        }
        .padding(8)
        .opacity(settings.widgetOpacity)
        .onAppear {
            //print("🕰️ FlipClockView appeared with time: \(widget.currentTime)")
        }
    }
}

struct ColonView: View {
    @State private var isPulsing = false
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(Color.white)
                .frame(width: 3, height: 3)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 0)
            Circle()
                .fill(Color.white)
                .frame(width: 3, height: 3)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 0)
        }
        .frame(width: 6, height: 36)
        .opacity(isPulsing ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)
        .onAppear {
            isPulsing = true
        }
    }
}

class FlipCardViewModel: ObservableObject {
    @Published var currentText: String = ""
    @Published var newText: String?
    @Published var oldText: String?
    @Published var animateTop: Bool = false
    @Published var animateBottom: Bool = false
    
    func updateText(to newValue: String) {
        guard newValue != currentText else { return }
        
        oldText = currentText
        newText = newValue
        animateTop = false
        animateBottom = false
        
        // First phase: Top half flips down
        withAnimation(.easeIn(duration: 0.2)) {
            animateTop = true
        }
        
        // Second phase: Bottom half flips up (starts slightly before top finishes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.2)) {
                self.animateBottom = true
            }
            
            // Reset after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.currentText = newValue
                self.oldText = nil
                self.newText = nil
                self.animateTop = false
                self.animateBottom = false
            }
        }
    }
}

struct FlipCard: View {
    let character: String
    @StateObject private var viewModel = FlipCardViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Top half
            ZStack {
                // New text (appears when top starts flipping)
                SingleFlipView(text: viewModel.newText ?? viewModel.currentText, type: .top)
                    .opacity(viewModel.animateTop ? 1 : 0)
                
                // Old text (disappears as top flips)
                SingleFlipView(text: viewModel.oldText ?? viewModel.currentText, type: .top)
                    .rotation3DEffect(
                        .degrees(viewModel.animateTop ? -89.9 : 0),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .bottom,
                        perspective: 0.8
                    )
                    .opacity(viewModel.animateTop ? 0 : 1)
            }
            
            // Separator line
            Rectangle()
                .fill(Color.black.opacity(0.4))
                .frame(width: 26, height: 0.8)
            
            // Bottom half
            ZStack {
                // Old text (visible until bottom starts flipping)
                SingleFlipView(text: viewModel.oldText ?? viewModel.currentText, type: .bottom)
                    .opacity(viewModel.animateBottom ? 0 : 1)
                
                // New text (appears as bottom flips up)
                SingleFlipView(text: viewModel.newText ?? viewModel.currentText, type: .bottom)
                    .rotation3DEffect(
                        .degrees(viewModel.animateBottom ? 0 : 89.9),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .top,
                        perspective: 0.8
                    )
                    .opacity(viewModel.animateBottom ? 1 : 0)
            }
        }
        .onChange(of: character) { oldValue, newValue in
            viewModel.updateText(to: newValue)
        }
        .onAppear {
            viewModel.currentText = character
        }
    }
}

struct SingleFlipView: View {
    let text: String
    let type: FlipType
    
    enum FlipType {
        case top
        case bottom
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.12, green: 0.12, blue: 0.12),
                    Color(red: 0.08, green: 0.08, blue: 0.08)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 26, height: 18)
            .cornerRadius(type == .top ? 4 : 0)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: type == .top ? 4 : 0)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            
            // Text positioned to show correct half
            Text(text)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 0.5)
                .frame(width: 26, height: 36)
                .offset(y: type == .top ? 9 : -9)
        }
        .frame(width: 26, height: 18)
        .clipped()
    }
}
