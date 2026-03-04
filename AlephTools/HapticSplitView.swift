import SwiftUI

#if os(macOS)
struct HapticSplitView<Left: View, Right: View>: View {
    @ViewBuilder let left: () -> Left
    @ViewBuilder let right: () -> Right

    @State private var splitFraction: CGFloat = 0.5
    @State private var dividerFlash = false
    @State private var hitBound = false

    private let minFraction: CGFloat = 0.25
    private let maxFraction: CGFloat = 0.75
    private let dividerWidth: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let leftWidth = max(totalWidth * minFraction, totalWidth * splitFraction)

            HStack(spacing: 0) {
                left()
                    .frame(width: min(totalWidth * maxFraction, leftWidth))

                Rectangle()
                    .fill(dividerFlash ? Color.accentColor : Color(nsColor: .separatorColor))
                    .frame(width: dividerWidth)
                    .contentShape(Rectangle().inset(by: -3))
                    .onHover { hovering in
                        if hovering {
                            NSCursor.resizeLeftRight.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 1)
                            .onChanged { value in
                                let newFraction = value.location.x / totalWidth
                                let clamped = min(maxFraction, max(minFraction, newFraction))

                                if clamped != newFraction && !hitBound {
                                    hitBound = true
                                    NSHapticFeedbackManager.defaultPerformer.perform(
                                        .alignment,
                                        performanceTime: .now
                                    )
                                    withAnimation(.easeOut(duration: 0.15)) { dividerFlash = true }
                                    withAnimation(.easeOut(duration: 0.15).delay(0.15)) { dividerFlash = false }
                                } else if clamped == newFraction {
                                    hitBound = false
                                }

                                splitFraction = clamped
                            }
                            .onEnded { _ in
                                hitBound = false
                            }
                    )

                right()
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
#endif
