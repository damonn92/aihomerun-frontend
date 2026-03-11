import Foundation
import CoreGraphics
import SwiftUI
import Vision

// MARK: - Joint Name Enum (19 body landmarks)

enum JointName: String, Codable, CaseIterable {
    case nose, leftEye, rightEye, leftEar, rightEar
    case neck
    case leftShoulder, rightShoulder
    case leftElbow, rightElbow
    case leftWrist, rightWrist
    case root // pelvis center
    case leftHip, rightHip
    case leftKnee, rightKnee
    case leftAnkle, rightAnkle

    /// Map to Apple Vision framework key
    var visionKey: VNHumanBodyPoseObservation.JointName {
        switch self {
        case .nose:           return .nose
        case .leftEye:        return .leftEye
        case .rightEye:       return .rightEye
        case .leftEar:        return .leftEar
        case .rightEar:       return .rightEar
        case .neck:           return .neck
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

    /// Short display label for overlay
    var shortLabel: String {
        switch self {
        case .nose:           return "Nose"
        case .leftEye:        return "L.Eye"
        case .rightEye:       return "R.Eye"
        case .leftEar:        return "L.Ear"
        case .rightEar:       return "R.Ear"
        case .neck:           return "Neck"
        case .leftShoulder:   return "L.Shldr"
        case .rightShoulder:  return "R.Shldr"
        case .leftElbow:      return "L.Elbow"
        case .rightElbow:     return "R.Elbow"
        case .leftWrist:      return "L.Wrist"
        case .rightWrist:     return "R.Wrist"
        case .root:           return "Root"
        case .leftHip:        return "L.Hip"
        case .rightHip:       return "R.Hip"
        case .leftKnee:       return "L.Knee"
        case .rightKnee:      return "R.Knee"
        case .leftAnkle:      return "L.Ankle"
        case .rightAnkle:     return "R.Ankle"
        }
    }
}

// MARK: - Per-Joint Data

/// A single recognized joint in normalized 0-1 coordinates (UIKit origin: top-left)
struct PoseJoint: Codable {
    let name: JointName
    let x: CGFloat
    let y: CGFloat
    let confidence: Float
}

// MARK: - Per-Frame Pose

/// Pose data for a single video frame
struct FramePose: Codable, Identifiable {
    let id: Int              // frame index
    let timestamp: Double    // seconds from video start
    let joints: [PoseJoint]
    let detected: Bool       // whether Vision found a body

    /// Lookup a joint by name, returning nil if below confidence threshold
    func joint(_ name: JointName, minConfidence: Float = 0.3) -> PoseJoint? {
        joints.first { $0.name == name && $0.confidence >= minConfidence }
    }
}

// MARK: - Full Video Pose Data

/// Complete pose analysis result for an entire video
struct VideoPoseData: Codable {
    let frameRate: Double
    let totalFrames: Int
    let frames: [FramePose]
    let videoWidth: Int
    let videoHeight: Int
}

// MARK: - Skeleton Topology (15 bone connections)

enum SkeletonConnection: CaseIterable {
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
}

// MARK: - Computed Angle

struct ComputedAngle {
    let name: String
    let degrees: Double
    let position: CGPoint   // normalized position for the label
    let jointName: JointName
}

// MARK: - Drawing Annotations

enum StrokeColor: String, Codable, CaseIterable {
    case red, blue, green, yellow, white

    var swiftUIColor: Color {
        switch self {
        case .red:    return Color.hrRed
        case .blue:   return Color.hrBlue
        case .green:  return Color.hrGreen
        case .yellow: return Color.hrGold
        case .white:  return .white
        }
    }
}

struct DrawingStroke: Identifiable, Codable {
    let id: UUID
    var points: [CGPoint]
    let color: StrokeColor
    let lineWidth: CGFloat
    let frameTimestamp: Double

    init(points: [CGPoint] = [], color: StrokeColor = .red, lineWidth: CGFloat = 3, frameTimestamp: Double) {
        self.id = UUID()
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.frameTimestamp = frameTimestamp
    }
}

// Note: CGPoint conforms to Codable natively in iOS 26+ SDK
