import SwiftUI
import AVFoundation

// MARK: - Trim Timeline View

/// Displays a video thumbnail strip with velocity waveform overlay and draggable trim handles.
struct TrimTimelineView: View {
    let videoURL: URL
    let velocities: [Double]          // Normalized 0-1 velocity per scan frame
    let scanTimestamps: [Double]      // Timestamps for each velocity entry
    let videoDuration: Double
    @Binding var trimStart: Double
    @Binding var trimEnd: Double
    let peakTime: Double

    @State private var thumbnails: [UIImage] = []
    @State private var isDraggingStart = false
    @State private var isDraggingEnd = false
    @State private var dragOriginStart: Double = 0   // captured at drag begin
    @State private var dragOriginEnd: Double = 0     // captured at drag begin

    private let timelineHeight: CGFloat = 56
    private let handleWidth: CGFloat = 20  // wider hit area for easier grabbing

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width

            ZStack(alignment: .leading) {
                // 1. Thumbnail strip
                thumbnailStrip(width: totalWidth)

                // 2. Dimmed areas outside trim range
                dimmedOverlay(width: totalWidth)

                // 3. Velocity waveform
                velocityWaveform(width: totalWidth)

                // 4. Peak marker
                peakMarker(width: totalWidth)

                // 5. Trim handles
                trimHandles(width: totalWidth)

                // 6. Trim duration label
                trimDurationLabel(width: totalWidth)
            }
            .frame(height: timelineHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.hrStroke, lineWidth: 1)
            )
        }
        .frame(height: timelineHeight)
        .onAppear { generateThumbnails() }
    }

    // MARK: - Thumbnail Strip

    private func thumbnailStrip(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            if thumbnails.isEmpty {
                Color.hrCard
            } else {
                ForEach(Array(thumbnails.enumerated()), id: \.offset) { _, img in
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width / CGFloat(max(1, thumbnails.count)),
                               height: timelineHeight)
                        .clipped()
                }
            }
        }
        .frame(width: width, height: timelineHeight)
    }

    // MARK: - Dimmed Overlay

    private func dimmedOverlay(width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            // Left dim
            Color.black.opacity(0.55)
                .frame(width: xForTime(trimStart, width: width))

            // Right dim
            Color.black.opacity(0.55)
                .frame(width: max(0, width - xForTime(trimEnd, width: width)))
                .offset(x: xForTime(trimEnd, width: width))
        }
        .frame(width: width, height: timelineHeight)
        .allowsHitTesting(false)
    }

    // MARK: - Velocity Waveform

    private func velocityWaveform(width: CGFloat) -> some View {
        Canvas { context, size in
            guard velocities.count >= 2 else { return }
            let waveHeight = size.height * 0.45
            let baseY = size.height * 0.85

            var path = Path()
            for (i, vel) in velocities.enumerated() {
                let t = i < scanTimestamps.count ? scanTimestamps[i] : Double(i) / Double(velocities.count) * videoDuration
                let x = (t / videoDuration) * Double(size.width)
                let y = baseY - vel * waveHeight

                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            context.stroke(path,
                           with: .color(Color.hrBlue.opacity(0.8)),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

            // Fill under the curve
            var fillPath = path
            if let lastTimestamp = scanTimestamps.last {
                let lastX = (lastTimestamp / videoDuration) * Double(size.width)
                fillPath.addLine(to: CGPoint(x: lastX, y: baseY))
            }
            if let firstTimestamp = scanTimestamps.first {
                let firstX = (firstTimestamp / videoDuration) * Double(size.width)
                fillPath.addLine(to: CGPoint(x: firstX, y: baseY))
            }
            fillPath.closeSubpath()

            context.fill(fillPath, with: .color(Color.hrBlue.opacity(0.15)))
        }
        .frame(width: width, height: timelineHeight)
        .allowsHitTesting(false)
    }

    // MARK: - Peak Marker

    private func peakMarker(width: CGFloat) -> some View {
        let peakX = xForTime(peakTime, width: width)
        return ZStack {
            // Vertical line
            Rectangle()
                .fill(Color.hrOrange)
                .frame(width: 2, height: timelineHeight)
                .offset(x: peakX - 1)

            // Triangle marker at top
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 8))
                .foregroundStyle(Color.hrOrange)
                .offset(x: peakX - 4, y: -timelineHeight / 2 + 6)
        }
        .frame(width: width, height: timelineHeight, alignment: .leading)
        .allowsHitTesting(false)
    }

    // MARK: - Trim Handles

    private func trimHandles(width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            // Top/bottom borders of trim region
            let startX = xForTime(trimStart, width: width)
            let endX = xForTime(trimEnd, width: width)
            let regionWidth = max(0, endX - startX)

            Rectangle()
                .fill(Color.hrBlue)
                .frame(width: regionWidth, height: 2)
                .offset(x: startX, y: -timelineHeight / 2 + 1)
                .allowsHitTesting(false)

            Rectangle()
                .fill(Color.hrBlue)
                .frame(width: regionWidth, height: 2)
                .offset(x: startX, y: timelineHeight / 2 - 1)
                .allowsHitTesting(false)

            // Left handle — use .minimumDistance(0) + translation for silky drag
            trimHandle(isStart: true)
                .position(x: xForTime(trimStart, width: width), y: timelineHeight / 2)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            if !isDraggingStart {
                                isDraggingStart = true
                                dragOriginStart = trimStart
                            }
                            let deltaTime = Double(value.translation.width / width) * videoDuration
                            let newTime = dragOriginStart + deltaTime
                            trimStart = max(0, min(newTime, trimEnd - 0.5))
                        }
                        .onEnded { _ in isDraggingStart = false }
                )

            // Right handle
            trimHandle(isStart: false)
                .position(x: xForTime(trimEnd, width: width), y: timelineHeight / 2)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            if !isDraggingEnd {
                                isDraggingEnd = true
                                dragOriginEnd = trimEnd
                            }
                            let deltaTime = Double(value.translation.width / width) * videoDuration
                            let newTime = dragOriginEnd + deltaTime
                            trimEnd = min(videoDuration, max(newTime, trimStart + 0.5))
                        }
                        .onEnded { _ in isDraggingEnd = false }
                )
        }
        .frame(width: width, height: timelineHeight, alignment: .leading)
    }

    private func trimHandle(isStart: Bool) -> some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(Color.hrBlue)
            .frame(width: handleWidth, height: timelineHeight)
            .overlay(
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 3, height: 16)
            )
    }

    // MARK: - Trim Duration Label

    private func trimDurationLabel(width: CGFloat) -> some View {
        let startX = xForTime(trimStart, width: width)
        let endX = xForTime(trimEnd, width: width)
        let centerX = (startX + endX) / 2
        let dur = trimEnd - trimStart

        return Text(String(format: "%.1fs", dur))
            .font(.system(size: 9, weight: .bold).monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.hrBlue.opacity(0.8))
            .clipShape(Capsule())
            .offset(x: centerX - 16, y: -timelineHeight / 2 + 14)
            .frame(width: width, height: timelineHeight, alignment: .leading)
            .allowsHitTesting(false)
    }

    // MARK: - Coordinate Mapping

    private func xForTime(_ time: Double, width: CGFloat) -> CGFloat {
        guard videoDuration > 0 else { return 0 }
        return CGFloat(time / videoDuration) * width
    }

    private func timeForX(_ x: CGFloat, width: CGFloat) -> Double {
        guard width > 0 else { return 0 }
        return Double(x / width) * videoDuration
    }

    // MARK: - Thumbnail Generation

    private func generateThumbnails() {
        Task.detached(priority: .utility) {
            let asset = AVAsset(url: videoURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 120, height: 80)

            let dur = try? await asset.load(.duration).seconds
            let totalDur = dur ?? videoDuration
            guard totalDur > 0 else { return }

            // Generate ~10 thumbnails evenly spaced
            let count = min(12, max(4, Int(totalDur / 2)))
            var images: [UIImage] = []

            for i in 0..<count {
                let time = CMTime(seconds: totalDur * Double(i) / Double(count), preferredTimescale: 600)
                if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                    images.append(UIImage(cgImage: cgImage))
                }
            }

            await MainActor.run {
                self.thumbnails = images
            }
        }
    }
}
