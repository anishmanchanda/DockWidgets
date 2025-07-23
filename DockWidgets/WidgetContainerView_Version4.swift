import SwiftUI

struct WidgetContainerView: View {
    @ObservedObject var widgetManager: WidgetManager
    
    init(window: OverlayWindow, widgetManager: WidgetManager) {
        self.widgetManager = widgetManager
    }
    
    var body: some View {
        RightClickableContainer(content: AnyView(widgetContent))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                //print("🎯 WidgetContainerView appeared with \(widgetManager.widgets.count) widgets")
//                for (index, widget) in widgetManager.widgets.enumerated() {
//                    print("   Widget \(index): position=\(widget.position), size=\(widget.size), visible=\(widget.isVisible)")
//                }
            }
    }
    
    private var widgetContent: some View {
        ZStack {
            // Remove debug backgrounds - keep it clean
            // Color.red.opacity(0.3)
            
            // Remove debug text
            // Text("WIDGET AREA")
            
            // Widgets
            ForEach(widgetManager.widgets) { widget in
                widget.createView()
                    .position(widget.position)
                    .opacity(1.0)  // Force full opacity always
                    .onAppear {
                        //print("🎯 Widget appeared at position \(widget.position) with size \(widget.size)")
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
