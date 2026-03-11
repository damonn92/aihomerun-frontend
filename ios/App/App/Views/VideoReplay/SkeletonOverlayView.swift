import SwiftUI

// MARK: - Skeleton Overlay (Canvas rendering)

struct SkeletonOverlayView: View {
    @ObservedObject var poseVM: PoseOverlayViewModel
    let currentTime: Double

    private let minConfidence: Float = 0.3

    var body: some View {
        GeometryReader { _ in
            Canvas { context, canvasSize in
                // 1. Draw skeleton bones
                if poseVM.showSkeleton, let pose = poseVM.currentPose, pose.detected {
                    drawBones(context: &context, pose: pose, size: canvasSize)
                    drawJoints(context: &context, pose: pose, size: canvasSize)
                }

                // 2. Draw joint labels
                if poseVM.showJointLabels, let pose = poseVM.currentPose, pose.detected {
                    drawJointLabels(context: &context, pose: pose, size: canvasSize)
                }

                // 3. Draw angle annotations
                if poseVM.showAngles {
                    drawAngles(context: &context, angles: poseVM.computedAngles, size: canvasSize)
                }

                // 4. Draw saved strokes for current frame
                let frameStrokes = poseVM.strokes.filter { abs($0.frameTimestamp - currentTime) < 0.05 }
                for stroke in frameStrokes {
                    drawStroke(context: &context, stroke: stroke)
                }

                // 5. Draw active stroke
                if let active = poseVM.currentStroke {
                    drawStroke(context: &context, stroke: active)
                }
            }
            .allowsHitTesting(poseVM.isDrawingMode)
            .gesture(poseVM.isDrawingMode ? drawingGesture : nil)
        }
    }

    // MARK: - Drawing Gesture

    private var drawingGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                if poseVM.currentStroke == nil {
                    poseVM.beginStroke(at: value.startLocation, frameTime: currentTime)
                }
                poseVM.continueStroke(to: value.location)
            }
            .onEnded { _ in
                poseVM.endStroke()
            }
    }

    // MARK: - Canvas Drawing Helpers

    private func drawBones(context: inout GraphicsContext, pose: FramePose, size: CGSize) {
        for connection in SkeletonConnection.allCases {
            guard let from = pose.joint(connection.from, minConfidence: minConfidence),
                  let to = pose.joint(connection.to, minConfidence: minConfidence)
            else { continue }

            let p1 = denormalize(x: from.x, y: from.y, in: size)
            let p2 = denormalize(x: to.x, y: to.y, in: size)

            var path = Path()
            path.move(to: p1)
            path.addLine(to: p2)

            context.stroke(path,
                           with: .color(Color.hrGreen.opacity(poseVM.skeletonOpacity)),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
    }

    private func drawJoints(context: inout GraphicsContext, pose: FramePose, size: CGSize) {
        let dotRadius: CGFloat = 3.5
        for joint in pose.joints where joint.confidence >= minConfidence {
            let center = denormalize(x: joint.x, y: joint.y, in: size)
            let rect = CGRect(x: center.x - dotRadius, y: center.y - dotRadius,
                              width: dotRadius * 2, height: dotRadius * 2)

            context.fill(Path(ellipseIn: rect), with: .color(.white))
            context.stroke(Path(ellipseIn: rect),
                           with: .color(Color.hrGreen),
                           lineWidth: 1.5)
        }
    }

    private func drawJointLabels(context: inout GraphicsContext, pose: FramePose, size: CGSize) {
        for joint in pose.joints where joint.confidence >= minConfidence {
            let center = denormalize(x: joint.x, y: joint.y, in: size)
            let text = Text(joint.name.shortLabel)
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(.white.opacity(0.8))
            context.draw(context.resolve(text),
                         at: CGPoint(x: center.x, y: center.y - 9))
        }
    }

    private func drawAngles(context: inout GraphicsContext, angles: [ComputedAngle], size: CGSize) {
        for angle in angles {
            let pos = denormalize(x: angle.position.x, y: angle.position.y, in: size)
            let label = String(format: "%.0f\u{00B0}", angle.degrees)
            let text = Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Color.hrGold)
            context.draw(context.resolve(text),
                         at: CGPoint(x: pos.x + 14, y: pos.y - 8))
        }
    }

    private func drawStroke(context: inout GraphicsContext, stroke: DrawingStroke) {
        guard stroke.points.count > 1 else { return }
        var path = Path()
        path.move(to: stroke.points[0])
        for point in stroke.points.dropFirst() {
            path.addLine(to: point)
        }
        context.stroke(path,
                       with: .color(stroke.color.swiftUIColor),
                       style: StrokeStyle(lineWidth: stroke.lineWidth, lineCap: .round, lineJoin: .round))
    }

    /// Convert normalized 0-1 coordinates to canvas pixel coordinates
    private func denormalize(x: CGFloat, y: CGFloat, in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}

// MARK: - Pose Analysis Toolbar

struct PoseToolbar: View {
    @ObservedObject var poseVM: PoseOverlayViewModel

    var body: some View {
        VStack(spacing: 6) {
            // Always-visible status + manual trigger
            analysisStatusBar

            // Analysis progress
            if poseVM.isAnalyzing {
                analysisProgressBar
            }

            // Toggle controls (only after analysis)
            if poseVM.poseData != nil {
                HStack(spacing: 4) {
                    toggleButton(icon: "figure.stand", label: "Skeleton",
                                 isOn: $poseVM.showSkeleton, color: .hrGreen)
                    toggleButton(icon: "tag.fill", label: "Labels",
                                 isOn: $poseVM.showJointLabels, color: .hrBlue)
                    toggleButton(icon: "angle", label: "Angles",
                                 isOn: $poseVM.showAngles, color: .hrGold)

                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1, height: 18)
                        .padding(.horizontal, 2)

                    drawingToggle
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.hrStroke, lineWidth: 1)
                )
            }

            // Drawing tools (only in draw mode)
            if poseVM.isDrawingMode {
                drawingToolbar
            }
        }
    }

    // MARK: - Always-Visible Analysis Status Bar

    private var analysisStatusBar: some View {
        HStack(spacing: 8) {
            // Status icon
            Group {
                if poseVM.isAnalyzing {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color.hrBlue)
                        .scaleEffect(0.7)
                } else if poseVM.analysisError != nil {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.hrOrange)
                } else if let data = poseVM.poseData {
                    Image(systemName: data.frames.contains { $0.detected } ? "figure.stand" : "figure.stand.line.dotted.figure.stand")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.hrGreen)
                } else {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .frame(width: 20)

            // Status text
            VStack(alignment: .leading, spacing: 1) {
                Text(analysisStatusTitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                Text(analysisStatusDetail)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
            }

            Spacer()

            // Manual start / retry button
            if !poseVM.isAnalyzing && poseVM.poseData == nil {
                Button {
                    poseVM.retryAnalysis()
                } label: {
                    Text(poseVM.analysisError != nil ? "Retry" : "Analyze")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.hrBlue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(analysisStatusBorderColor, lineWidth: 1)
        )
    }

    private var analysisStatusTitle: String {
        if poseVM.isAnalyzing {
            return "Analyzing Pose... \(Int(poseVM.analysisProgress * 100))%"
        } else if poseVM.analysisError != nil {
            return "Analysis Failed"
        } else if let data = poseVM.poseData {
            let detected = data.frames.filter { $0.detected }.count
            return detected > 0 ? "Pose Ready (\(detected)/\(data.totalFrames) frames)" : "No Body Detected"
        } else {
            return "Pose Analysis"
        }
    }

    private var analysisStatusDetail: String {
        if poseVM.isAnalyzing {
            return "Processing video frames..."
        } else if let error = poseVM.analysisError {
            return String(error.prefix(60))
        } else if poseVM.poseData != nil {
            return poseVM.usedMockData ? "⚠️ Simulator mock data — test on device" : "Toggle skeleton, angles, labels below"
        } else {
            return poseVM.lastVideoURL != nil ? "Tap Analyze to start" : "Waiting for video..."
        }
    }

    private var analysisStatusBorderColor: Color {
        if poseVM.isAnalyzing { return Color.hrBlue.opacity(0.3) }
        if poseVM.analysisError != nil { return Color.hrOrange.opacity(0.3) }
        if poseVM.poseData != nil { return Color.hrGreen.opacity(0.3) }
        return Color.hrStroke
    }

    // MARK: - Analysis Progress Bar

    private var analysisProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 3)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.hrBlue)
                    .frame(width: geo.size.width * poseVM.analysisProgress, height: 3)
                    .animation(.linear(duration: 0.15), value: poseVM.analysisProgress)
            }
        }
        .frame(height: 3)
        .padding(.horizontal, 4)
    }

    // MARK: - Toggle Button

    private func toggleButton(icon: String, label: String, isOn: Binding<Bool>, color: Color) -> some View {
        Button {
            withAnimation(.spring(duration: 0.2)) { isOn.wrappedValue.toggle() }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(isOn.wrappedValue ? .white : .white.opacity(0.35))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isOn.wrappedValue ? color.opacity(0.3) : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Drawing Mode Toggle

    private var drawingToggle: some View {
        Button {
            withAnimation(.spring(duration: 0.2)) { poseVM.isDrawingMode.toggle() }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "pencil.tip")
                    .font(.system(size: 9, weight: .semibold))
                Text("Draw")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(poseVM.isDrawingMode ? .white : .white.opacity(0.35))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(poseVM.isDrawingMode ? Color.hrRed.opacity(0.3) : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Drawing Toolbar

    private var drawingToolbar: some View {
        HStack(spacing: 8) {
            // Color picker
            ForEach(StrokeColor.allCases, id: \.self) { color in
                Button {
                    poseVM.activeColor = color
                } label: {
                    Circle()
                        .fill(color.swiftUIColor)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Circle().stroke(.white, lineWidth: poseVM.activeColor == color ? 2 : 0)
                        )
                }
                .buttonStyle(.plain)
            }

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 16)
                .padding(.horizontal, 2)

            // Line width buttons
            ForEach([CGFloat(2), CGFloat(3), CGFloat(5)], id: \.self) { width in
                Button {
                    poseVM.activeLineWidth = width
                } label: {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(poseVM.activeLineWidth == width ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 16, height: width)
                }
                .buttonStyle(.plain)
            }

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 16)
                .padding(.horizontal, 2)

            // Undo
            Button { poseVM.undoLastStroke() } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            // Clear
            Button { poseVM.clearAnnotations() } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.hrStroke, lineWidth: 1)
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}
