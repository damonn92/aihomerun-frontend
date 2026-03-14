import SwiftUI
import SceneKit

// MARK: - SceneKit UIViewRepresentable Wrapper

/// Wraps `SCNView` for SwiftUI, allowing 3D skeleton rendering with orbit camera controls.
@available(iOS 17, *)
struct Skeleton3DSceneView: UIViewRepresentable {
    let scene: SCNScene
    @Binding var cameraNode: SCNNode?

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.allowsCameraControl = true
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X
        scnView.autoenablesDefaultLighting = false
        scnView.isJitteringEnabled = true  // smoother rendering

        // Set up default camera if none provided
        if let cam = cameraNode {
            scnView.pointOfView = cam
        }

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = scene
        if let cam = cameraNode {
            uiView.pointOfView = cam
        }
    }
}
