import SwiftUI

struct WidgetContainerView: View {
    @StateObject private var widgetManager = WidgetManager(window: OverlayWindow())
    
    var body: some View {
        ZStack {
            // Transparent background
            Color.clear
            
            // Widgets
            ForEach(widgetManager.widgets) { widget in
                widget.createView()
                    .position(widget.position)
                    .opacity(widget.isVisible ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}