import Foundation
import simd
import Vision

// MARK: - 3D Joint Data

/// A single 3D joint, positions in meters relative to root (hip center).
struct Pose3DJoint: Codable {
    let name: JointName
    let x: Float        // meters, root-relative
    let y: Float        // meters, root-relative
    let z: Float        // meters, root-relative (depth)
    let confidence: Float

    var simdPosition: SIMD3<Float> {
        SIMD3(x, y, z)
    }
}

// MARK: - 3D Frame Pose

/// Pose data for a single video frame in 3D space.
struct FramePose3D: Codable, Identifiable {
    let id: Int              // frame index
    let timestamp: Double    // seconds from video start
    let joints: [Pose3DJoint]
    let detected: Bool       // whether Vision found a 3D body
    let bodyHeight: Float?   // estimated height in meters

    /// Lookup a joint by name, returning nil if below confidence threshold
    func joint(_ name: JointName, minConfidence: Float = 0.3) -> Pose3DJoint? {
        joints.first { $0.name == name && $0.confidence >= minConfidence }
    }
}

// MARK: - Full Video 3D Pose Data

/// Complete 3D pose analysis result for an entire video.
struct VideoPose3DData: Codable {
    let frameRate: Double
    let totalFrames: Int
    let frames: [FramePose3D]
    let videoWidth: Int
    let videoHeight: Int
}

// MARK: - 3D Skeleton Connection Topology

/// Bone connections for 3D skeleton rendering — mirrors the 2D SkeletonConnection.
enum Skeleton3DConnection: CaseIterable {
    case headToNeck
    case neckToLeftShoulder, neckToRightShoulder
    case leftShoulderToElbow, leftElbowToWrist
    case rightShoulderToElbow, rightElbowToWrist
    case neckToRoot
    case rootToLeftHip, rootToRightHip
    case leftHipToKnee, leftKneeToAnkle
    case rightHipToKnee, rightKneeToAnkle

    var from: JointName {
        switch self {
        case .headToNeck:           return .nose
        case .neckToLeftShoulder:   return .neck
        case .neckToRightShoulder:  return .neck
        case .leftShoulderToElbow:  return .leftShoulder
        case .leftElbowToWrist:     return .leftElbow
        case .rightShoulderToElbow: return .rightShoulder
        case .rightElbowToWrist:    return .rightElbow
        case .neckToRoot:           return .neck
        case .rootToLeftHip:        return .root
        case .rootToRightHip:       return .root
        case .leftHipToKnee:        return .leftHip
        case .leftKneeToAnkle:      return .leftKnee
        case .rightHipToKnee:       return .rightHip
        case .rightKneeToAnkle:     return .rightKnee
        }
    }

    var to: JointName {
        switch self {
        case .headToNeck:           return .neck
        case .neckToLeftShoulder:   return .leftShoulder
        case .neckToRightShoulder:  return .rightShoulder
        case .leftShoulderToElbow:  return .leftElbow
        case .leftElbowToWrist:     return .leftWrist
        case .rightShoulderToElbow: return .rightElbow
        case .rightElbowToWrist:    return .rightWrist
        case .neckToRoot:           return .root
        case .rootToLeftHip:        return .leftHip
        case .rootToRightHip:       return .rightHip
        case .leftHipToKnee:        return .leftKnee
        case .leftKneeToAnkle:      return .leftAnkle
        case .rightHipToKnee:       return .rightKnee
        case .rightKneeToAnkle:     return .rightAnkle
        }
    }

    /// Unique key for bone node identification in SceneKit
    var nodeKey: String {
        "bone_\(from.rawValue)_\(to.rawValue)"
    }
}

// MARK: - 3D Joint Mapping for Vision

/// Maps our JointName enum to VNHumanBodyPose3DObservation joint names (iOS 17+).
@available(iOS 17, *)
extension JointName {
    /// Map to Apple Vision 3D framework key. Returns nil for joints not available in 3D.
    var vision3DKey: VNHumanBodyPose3DObservation.JointName? {
        switch self {
        case .nose:           return .centerHead
        case .leftEye:        return nil  // Not available in 3D
        case .rightEye:       return nil
        case .leftEar:        return nil
        case .rightEar:       return nil
        case .neck:           return .centerShoulder
        case .leftShoulder:   return .leftShoulder
        case .rightShoulder:  return .rightShoulder
        case .leftElbow:      return .leftElbow
        case .rightElbow:     return .rightElbow
        case .leftWrist:      return .leftWrist
        case .rightWrist:     return .rightWrist
        case .root:           return .root
        case .leftHip:        return .leftHip
        case .rightHip:       return .rightHip
        case .leftKnee:       return .leftKnee
        case .rightKnee:      return .rightKnee
        case .leftAnkle:      return .leftAnkle
        case .rightAnkle:     return .rightAnkle
        }
    }
}
