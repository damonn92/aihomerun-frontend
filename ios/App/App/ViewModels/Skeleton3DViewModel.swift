import Foundation
import SwiftUI
import SceneKit

// MARK: - 3D Skeleton ViewModel

/// Manages 3D pose analysis lifecycle and SceneKit scene for 3D skeleton rendering.
@available(iOS 17, *)
@MainActor
class Skeleton3DViewModel: ObservableObject {
    @Published var pose3DData: VideoPose3DData?
    @Published var currentFrame3D: FramePose3D?
    @Published var isAnalyzing3D = false
    @Published var analysisProgress3D: Double = 0
    @Published var show3D = false           // 2D/3D toggle state
    @Published var error3D: String?

    let scene = SCNScene()
    @Published var cameraNode: SCNNode?

    // MARK: - Private

    private var jointNodes: [JointName: SCNNode] = [:]
    private var boneNodes: [String: SCNNode] = [:]
    private var groundNode: SCNNode?

    private let jointRadius: CGFloat = 0.018
    private let boneRadius: CGFloat = 0.008

    // Colors
    private let jointColor = UIColor(red: 0.0, green: 0.85, blue: 0.45, alpha: 1.0)    // .hrGreen
    private let boneColor = UIColor(red: 0.0, green: 0.85, blue: 0.45, alpha: 0.7)
    private let lowConfColor = UIColor(white: 0.5, alpha: 0.3)
    private let groundColor = UIColor(white: 0.3, alpha: 0.15)

    // MARK: - Init

    init() {
        setupScene()
    }

    // MARK: - Scene Setup

    func setupScene() {
        scene.background.contents = UIColor.clear

        // Ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor(white: 0.5, alpha: 1.0)
        ambientLight.light?.intensity = 600
        scene.rootNode.addChildNode(ambientLight)

        // Directional light (front-top)
        let dirLight = SCNNode()
        dirLight.light = SCNLight()
        dirLight.light?.type = .directional
        dirLight.light?.color = UIColor.white
        dirLight.light?.intensity = 800
        dirLight.light?.castsShadow = false
        dirLight.position = SCNVector3(0, 2, 3)
        dirLight.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(dirLight)

        // Camera
        let camera = SCNCamera()
        camera.fieldOfView = 35
        camera.zNear = 0.1
        camera.zFar = 20

        let camNode = SCNNode()
        camNode.camera = camera
        camNode.position = SCNVector3(0, 0.3, 2.8)  // Slightly above and in front
        camNode.look(at: SCNVector3(0, 0.1, 0))
        scene.rootNode.addChildNode(camNode)
        cameraNode = camNode

        // Ground grid
        setupGroundGrid()

        // Pre-create joint nodes
        for jointName in JointName.allCases {
            // Skip joints not available in 3D
            guard jointName.vision3DKey != nil else { continue }

            let sphere = SCNSphere(radius: jointRadius)
            sphere.segmentCount = 12
            sphere.firstMaterial?.diffuse.contents = jointColor
            sphere.firstMaterial?.emission.contents = jointColor.withAlphaComponent(0.2)

            let node = SCNNode(geometry: sphere)
            node.isHidden = true
            scene.rootNode.addChildNode(node)
            jointNodes[jointName] = node
        }

        // Pre-create bone nodes
        for conn in Skeleton3DConnection.allCases {
            // Only if both joints exist in 3D
            guard conn.from.vision3DKey != nil, conn.to.vision3DKey != nil else { continue }

            let cylinder = SCNCylinder(radius: boneRadius, height: 1.0)
            cylinder.radialSegmentCount = 8
            cylinder.firstMaterial?.diffuse.contents = boneColor

            let node = SCNNode(geometry: cylinder)
            node.isHidden = true
            scene.rootNode.addChildNode(node)
            boneNodes[conn.nodeKey] = node
        }
    }

    private func setupGroundGrid() {
        // Create a simple flat grid plane
        let gridSize: CGFloat = 2.0
        let plane = SCNPlane(width: gridSize, height: gridSize)
        plane.firstMaterial?.diffuse.contents = groundColor
        plane.firstMaterial?.isDoubleSided = true

        let node = SCNNode(geometry: plane)
        node.eulerAngles.x = -.pi / 2  // Lay flat
        node.position = SCNVector3(0, -0.80, 0)  // Below feet
        scene.rootNode.addChildNode(node)
        groundNode = node

        // Grid lines
        let lineSpacing: Float = 0.2
        let halfSize = Float(gridSize) / 2
        let lineColor = UIColor(white: 0.4, alpha: 0.2)

        for i in stride(from: -halfSize, through: halfSize, by: lineSpacing) {
            // X lines
            addGridLine(from: SCNVector3(i, -0.79, -halfSize),
                       to: SCNVector3(i, -0.79, halfSize),
                       color: lineColor)
            // Z lines
            addGridLine(from: SCNVector3(-halfSize, -0.79, i),
                       to: SCNVector3(halfSize, -0.79, i),
                       color: lineColor)
        }
    }

    private func addGridLine(from: SCNVector3, to: SCNVector3, color: UIColor) {
        let vertices = [from, to]
        let source = SCNGeometrySource(vertices: vertices)
        let indices: [Int32] = [0, 1]
        let data = Data(bytes: indices, count: MemoryLayout<Int32>.stride * indices.count)
        let element = SCNGeometryElement(data: data,
                                          primitiveType: .line,
                                          primitiveCount: 1,
                                          bytesPerIndex: MemoryLayout<Int32>.stride)
        let line = SCNGeometry(sources: [source], elements: [element])
        line.firstMaterial?.diffuse.contents = color
        let node = SCNNode(geometry: line)
        scene.rootNode.addChildNode(node)
    }

    // MARK: - Analysis

    func runAnalysis3D(videoURL: URL) async {
        isAnalyzing3D = true
        analysisProgress3D = 0
        error3D = nil

        do {
            let service = Pose3DDetectionService()
            let data = try await service.analyzeVideo3D(url: videoURL) { [weak self] progress in
                Task { @MainActor in
                    self?.analysisProgress3D = progress
                }
            }
            pose3DData = data
        } catch {
            error3D = error.localizedDescription
        }

        isAnalyzing3D = false
    }

    // MARK: - Load Cached

    func loadCachedPose3DData(_ data: VideoPose3DData) {
        pose3DData = data
    }

    // MARK: - Update Pose for Time

    func updatePose(forTime time: Double) {
        guard let data = pose3DData else { return }

        // Find closest frame
        let frame = closestFrame(in: data, at: time)
        currentFrame3D = frame

        guard let frame, frame.detected else {
            hideAll()
            return
        }

        // Update joint positions
        for joint in frame.joints {
            guard let node = jointNodes[joint.name] else { continue }
            node.isHidden = false

            // Position: Vision 3D returns root-relative meters
            // Y is up, X is left-right, Z is depth
            node.position = SCNVector3(joint.x, joint.y, joint.z)

            // Color by confidence
            if let sphere = node.geometry as? SCNSphere {
                if joint.confidence >= 0.3 {
                    sphere.firstMaterial?.diffuse.contents = jointColor
                    sphere.firstMaterial?.emission.contents = jointColor.withAlphaComponent(0.2)
                } else {
                    sphere.firstMaterial?.diffuse.contents = lowConfColor
                    sphere.firstMaterial?.emission.contents = UIColor.clear
                }
            }
        }

        // Update bone positions and orientations
        for conn in Skeleton3DConnection.allCases {
            guard let node = boneNodes[conn.nodeKey],
                  let fromJoint = frame.joint(conn.from),
                  let toJoint = frame.joint(conn.to)
            else {
                boneNodes[conn.nodeKey]?.isHidden = true
                continue
            }

            node.isHidden = false
            positionBone(node: node,
                        from: SCNVector3(fromJoint.x, fromJoint.y, fromJoint.z),
                        to: SCNVector3(toJoint.x, toJoint.y, toJoint.z))
        }
    }

    // MARK: - Camera Reset

    func resetCamera() {
        cameraNode?.position = SCNVector3(0, 0.3, 2.8)
        cameraNode?.look(at: SCNVector3(0, 0.1, 0))
    }

    // MARK: - Cleanup

    func cleanup() {
        pose3DData = nil
        currentFrame3D = nil
        show3D = false
        hideAll()
    }

    // MARK: - Private Helpers

    private func hideAll() {
        for (_, node) in jointNodes { node.isHidden = true }
        for (_, node) in boneNodes { node.isHidden = true }
    }

    private func closestFrame(in data: VideoPose3DData, at time: Double) -> FramePose3D? {
        guard !data.frames.isEmpty else { return nil }
        // Binary search would be faster, but for typical frame counts this is fine
        return data.frames.min(by: { abs($0.timestamp - time) < abs($1.timestamp - time) })
    }

    /// Position a cylinder bone between two 3D points.
    private func positionBone(node: SCNNode, from: SCNVector3, to: SCNVector3) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let dz = to.z - from.z
        let distance = sqrt(dx * dx + dy * dy + dz * dz)

        guard distance > 0.001 else {
            node.isHidden = true
            return
        }

        // Update cylinder height
        if let cylinder = node.geometry as? SCNCylinder {
            cylinder.height = CGFloat(distance)
        }

        // Position at midpoint
        node.position = SCNVector3(
            (from.x + to.x) / 2,
            (from.y + to.y) / 2,
            (from.z + to.z) / 2
        )

        // Orient cylinder along the bone direction
        // SCNCylinder is aligned along Y by default
        let direction = SCNVector3(dx, dy, dz)
        let up = SCNVector3(0, 1, 0)

        // Cross product to find rotation axis
        let cross = SCNVector3(
            up.y * direction.z - up.z * direction.y,
            up.z * direction.x - up.x * direction.z,
            up.x * direction.y - up.y * direction.x
        )
        let crossLength = sqrt(cross.x * cross.x + cross.y * cross.y + cross.z * cross.z)
        let dot = up.x * direction.x + up.y * direction.y + up.z * direction.z

        if crossLength > 0.001 {
            let angle = atan2(crossLength, dot)
            let axis = SCNVector3(cross.x / crossLength, cross.y / crossLength, cross.z / crossLength)
            node.rotation = SCNVector4(axis.x, axis.y, axis.z, angle)
        } else if dot < 0 {
            // Opposite direction — rotate 180 degrees
            node.rotation = SCNVector4(1, 0, 0, Float.pi)
        } else {
            // Same direction — no rotation
            node.rotation = SCNVector4(0, 0, 0, 0)
        }
    }
}
