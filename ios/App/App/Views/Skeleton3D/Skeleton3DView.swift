import SwiftUI
import SceneKit

// MARK: - 3D Skeleton View

/// Displays a 3D skeleton in a SceneKit scene view with orbit camera controls.
/// Requires iOS 17+ for VNDetectHumanBodyPose3DRequest data.
@available(iOS 17, *)
struct Skeleton3DView: View {
    @ObservedObject var vm: Skeleton3DViewModel
    let currentTime: Double

    var body: some View {
        ZStack {
            // SceneKit 3D view
            Skeleton3DSceneView(scene: vm.scene, cameraNode: $vm.cameraNode)
                .background(
                    LinearGradient(
                        colors: [Color(white: 0.08), Color(white: 0.04)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Overlay controls
            VStack {
                HStack {
                    // 3D badge
                    Label("3D", systemImage: "cube")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.hrBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.hrBlue.opacity(0.15))
                        .clipShape(Capsule())

                    Spacer()

                    // Reset camera button
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            vm.resetCamera()
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 28, height: 28)
                            .background(.ultraThinMaterial.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)

                Spacer()

                // Body height and frame info
                if let frame = vm.currentFrame3D, frame.detected {
                    HStack(spacing: 12) {
                        if let height = frame.bodyHeight {
                            infoTag(icon: "ruler", text: String(format: "%.2fm", height))
                        }
                        infoTag(icon: "cube.transparent", text: "\(frame.joints.count) joints")
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }

                // Analysis progress
                if vm.isAnalyzing3D {
                    HStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.hrBlue)
                            .scaleEffect(0.6)
                        Text("Analyzing 3D pose... \(Int(vm.analysisProgress3D * 100))%")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.bottom, 8)
                }

                // No 3D data available
                if !vm.isAnalyzing3D && vm.pose3DData == nil {
                    VStack(spacing: 6) {
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 28))
                            .foregroundStyle(.white.opacity(0.25))
                        Text("3D data not available")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onChange(of: currentTime) { newTime in
            vm.updatePose(forTime: newTime)
        }
    }

    // MARK: - Info Tag

    private func infoTag(icon: String, text: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .semibold))
            Text(text)
                .font(.system(size: 9, weight: .bold).monospacedDigit())
        }
        .foregroundStyle(.white.opacity(0.5))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial.opacity(0.4))
        .clipShape(Capsule())
    }
}
