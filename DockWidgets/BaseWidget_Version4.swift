import SwiftUI

class BaseWidget: ObservableObject, Identifiable {
    let id = UUID()
    @Published var position: CGPoint{
        didSet {
            print("📍Widget position updated to: \(position)")
        
    }
    }
    @Published var size: CGSize
    @Published var isVisible: Bool = true
    
    init(position: CGPoint, size: CGSize = CGSize(width: 300, height: 100)) {
        self.position = position
        self.size = size
    }
    
    func createView() -> AnyView {
        fatalError("Subclasses must implement createView()")
    }
}
