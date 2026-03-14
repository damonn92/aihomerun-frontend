import SwiftUI

// MARK: - Ghost Overlay Comparison View

struct GhostOverlayView: View {
    @ObservedObject var vm: ComparisonViewModel

    private let minConfidence: Float = 0.3

    var body: some View {
        ZStack {
            // Base: Left video + left skeleton (green)
            if vm.leftSession.videoAvailable {
                ZStack {
                    Color.black
                    PlayerLayerView(player: vm.leftPlayerVM.player)

                    // Left skeleton (green, standard)
                    SkeletonOverlayView(poseVM: vm.leftPoseVM, currentTime: vm.leftPlayerVM.currentTime)

                    // Right skeleton (orange ghost)
                    GhostSkeletonCanvas(
                        poseVM: vm.rightPoseVM,
                        currentTime: vm.rightPlayerVM.currentTime,
                        ghostColor: Color.hrOrange,
                        opacity: vm.ghostOpacity
                    )
                }
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color.hrCard, Color.black.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    VStack(spacing: 8) {
                        Image(systemName: "film.slash")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.3))
                        Text("Video Unavailable")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.45))
                        Text("Score comparison shown below")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.25))
                    }
                }
            }

            // Legend overlay (bottom-left)
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    legendDot(color: .hrGreen, label: vm.leftSession.displayLabel)
                    legendDot(color: .hrOrange, label: vm.rightSession.displayLabel)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Session badges (top corners)
            VStack {
                HStack {
                    sessionBadge(session: vm.leftSession, label: "A", color: .hrGreen)
                    Spacer()
                    sessionBadge(session: vm.rightSession, label: "B", color: .hrOrange)
                }
                .padding(8)
                Spacer()
            }

            // Analysis loading
            if vm.leftPoseVM.isAnalyzing || vm.rightPoseVM.isAnalyzing {
                VStack {
                    Spacer()
                    HStack(spacing: 4) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.hrBlue)
                            .scaleEffect(0.5)
                        Text("Analyzing...")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.bottom, 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Legend Dot

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - Session Badge

    private func sessionBadge(session: ComparisonSession, label: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 14, height: 14)
                .background(color)
                .clipShape(Circle())

            if let score = session.overallScore {
                Text("\(score)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.hrGold)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - Ghost Skeleton Canvas

/// Renders a second skeleton in a ghost color, for overlay comparison.
/// Only draws bones and joints — no labels, angles, or drawing strokes.
struct GhostSkeletonCanvas: View {
    @ObservedObject var poseVM: PoseOverlayViewModel
    let currentTime: Double
    let ghostColor: Color
    let opacity: Double

    private let minConfidence: Float = 0.3

    var body: some View {
        Canvas { context, canvasSize in
            guard let pose = poseVM.currentPose, pose.detected else { return }
            drawGhostBones(context: &context, pose: pose, size: canvasSize)
            drawGhostJoints(context: &context, pose: pose, size: canvasSize)
        }
        .opacity(opacity)
        .allowsHitTesting(false)
    }

    // MARK: - Drawing

    private func drawGhostBones(context: inout GraphicsContext, pose: FramePose, size: CGSize) {
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
                           with: .color(ghostColor),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
    }

    private func drawGhostJoints(context: inout GraphicsContext, pose: FramePose, size: CGSize) {
        let dotRadius: CGFloat = 3.0
        for joint in pose.joints where joint.confidence >= minConfidence {
            let center = denormalize(x: joint.x, y: joint.y, in: size)
            let rect = CGRect(x: center.x - dotRadius, y: center.y - dotRadius,
                              width: dotRadius * 2, height: dotRadius * 2)

            context.fill(Path(ellipseIn: rect), with: .color(ghostColor.opacity(0.9)))
        }
    }

    private func denormalize(x: CGFloat, y: CGFloat, in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}
