import SwiftUI

// MARK: - Custom Video Timeline / Scrubber

struct VideoTimelineView: View {
    /// Current progress 0...1
    let progress: Double
    /// Current time formatted (e.g. "0:02")
    let currentTime: String
    /// Duration formatted (e.g. "0:14")
    let duration: String
    /// Called when user drags to a new fraction
    let onSeek: (Double) -> Void
    /// Called when drag begins (pause playback)
    var onDragStart: (() -> Void)? = nil
    /// Called when drag ends
    var onDragEnd: (() -> Void)? = nil

    @State private var isDragging = false
    @State private var dragFraction: Double = 0

    private let trackHeight: CGFloat = 4
    private let thumbSize: CGFloat = 12
    private let thumbDragSize: CGFloat = 18
    private let hitArea: CGFloat = 24

    var body: some View {
        VStack(spacing: 6) {
            // Track + thumb
            GeometryReader { geo in
                let w = geo.size.width
                let fraction = isDragging ? dragFraction : progress

                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(Color.primary.opacity(0.12))
                        .frame(height: trackHeight)

                    // Filled track
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(Color.hrBlue)
                        .frame(width: max(0, w * fraction), height: trackHeight)

                    // Thumb
                    Circle()
                        .fill(Color.hrBlue)
                        .frame(
                            width: isDragging ? thumbDragSize : thumbSize,
                            height: isDragging ? thumbDragSize : thumbSize
                        )
                        .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                        .offset(x: thumbOffset(fraction: fraction, width: w))
                        .animation(.spring(duration: 0.15), value: isDragging)
                }
                .frame(height: hitArea)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                onDragStart?()
                            }
                            let frac = min(max(value.location.x / w, 0), 1)
                            dragFraction = frac
                            onSeek(frac)
                        }
                        .onEnded { _ in
                            isDragging = false
                            onDragEnd?()
                        }
                )
            }
            .frame(height: hitArea)

            // Time labels
            HStack {
                Text(currentTime)
                    .font(.system(size: 10, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.primary.opacity(0.65))
                Spacer()
                Text(duration)
                    .font(.system(size: 10, weight: .semibold).monospacedDigit())
                    .foregroundStyle(.primary.opacity(0.65))
            }
        }
    }

    /// Center the thumb on the fraction position
    private func thumbOffset(fraction: Double, width: CGFloat) -> CGFloat {
        let size = isDragging ? thumbDragSize : thumbSize
        return (width * fraction) - (size / 2)
    }
}
