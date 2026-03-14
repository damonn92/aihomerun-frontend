import UIKit
import AVFoundation

// MARK: - Report Export Service

/// Generates PDF reports and shareable images from analysis results.
class ReportExportService {

    // MARK: - Report Data

    struct ReportData {
        let analysisResult: AnalysisResult
        let keyFrameImage: UIImage?     // Key frame screenshot with skeleton overlay
        let videoURL: URL?
        let playerName: String?
        let playerAge: Int?
        let date: Date
    }

    // MARK: - PDF Generation

    /// Generate a single-page PDF report from analysis data.
    static func generatePDF(from data: ReportData) -> Data {
        let pageWidth: CGFloat = 612    // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            context.beginPage()

            var yOffset: CGFloat = margin
            let fb = data.analysisResult.feedback
            let metrics = data.analysisResult.metrics

            // MARK: Header
            yOffset = drawHeader(yOffset: yOffset, margin: margin, contentWidth: contentWidth, date: data.date)

            // MARK: Player Info + Score
            yOffset = drawScoreSection(yOffset: yOffset, margin: margin, contentWidth: contentWidth, feedback: fb, data: data)

            // MARK: Key Frame Image
            if let image = data.keyFrameImage {
                yOffset += 12
                let imgHeight = min(200.0, contentWidth * 0.45)
                let imgWidth = imgHeight * (image.size.width / image.size.height)
                let imgX = margin + (contentWidth - imgWidth) / 2
                image.draw(in: CGRect(x: imgX, y: yOffset, width: imgWidth, height: imgHeight))
                yOffset += imgHeight + 12
            }

            // MARK: Sub-scores
            yOffset = drawSubScores(yOffset: yOffset, margin: margin, contentWidth: contentWidth, feedback: fb)

            // MARK: Biomechanics
            yOffset = drawBiomechanics(yOffset: yOffset, margin: margin, contentWidth: contentWidth, metrics: metrics)

            // MARK: Strengths & Improvements
            yOffset = drawStrengthsImprovements(yOffset: yOffset, margin: margin, contentWidth: contentWidth, feedback: fb)

            // MARK: Drill Recommendation
            if let drill = fb.drill {
                yOffset = drawDrill(yOffset: yOffset, margin: margin, contentWidth: contentWidth, drill: drill)
            }

            // MARK: Footer
            drawFooter(pageHeight: pageHeight, margin: margin, contentWidth: contentWidth)
        }
    }

    // MARK: - Share Image Generation

    /// Generate a square shareable image (suitable for social media).
    static func generateShareImage(from data: ReportData) -> UIImage {
        let size = CGSize(width: 1080, height: 1080)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let fb = data.analysisResult.feedback

            // Background
            UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1.0).setFill()
            ctx.fill(rect)

            // Gradient accent bar
            let gradientRect = CGRect(x: 0, y: 0, width: size.width, height: 6)
            UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 1.0).setFill()
            UIBezierPath(rect: gradientRect).fill()

            let margin: CGFloat = 60
            var y: CGFloat = 50

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .black),
                .foregroundColor: UIColor.white
            ]
            "AIHomeRun Report".draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
            y += 50

            // Date
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.5)
            ]
            dateFormatter.string(from: data.date).draw(at: CGPoint(x: margin, y: y), withAttributes: dateAttrs)
            y += 50

            // Big score circle
            let scoreSize: CGFloat = 200
            let scoreX = (size.width - scoreSize) / 2
            let scoreRect = CGRect(x: scoreX, y: y, width: scoreSize, height: scoreSize)
            let gradeColor = scoreUIColor(for: fb.grade)
            gradeColor.withAlphaComponent(0.15).setFill()
            UIBezierPath(ovalIn: scoreRect).fill()
            gradeColor.withAlphaComponent(0.5).setStroke()
            let path = UIBezierPath(ovalIn: scoreRect.insetBy(dx: 2, dy: 2))
            path.lineWidth = 3
            path.stroke()

            let scoreAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 64, weight: .black),
                .foregroundColor: gradeColor
            ]
            let scoreStr = "\(fb.overallScore)"
            let scoreStrSize = scoreStr.size(withAttributes: scoreAttrs)
            scoreStr.draw(at: CGPoint(x: scoreX + (scoreSize - scoreStrSize.width) / 2,
                                       y: y + (scoreSize - scoreStrSize.height) / 2 - 10),
                         withAttributes: scoreAttrs)

            let gradeAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 28, weight: .bold),
                .foregroundColor: gradeColor.withAlphaComponent(0.7)
            ]
            let gradeStrSize = fb.grade.size(withAttributes: gradeAttrs)
            fb.grade.draw(at: CGPoint(x: scoreX + (scoreSize - gradeStrSize.width) / 2,
                                       y: y + (scoreSize - scoreStrSize.height) / 2 + 50),
                         withAttributes: gradeAttrs)
            y += scoreSize + 30

            // Sub-scores bar
            let subWidth = (size.width - margin * 2 - 40) / 3
            let subScores = [
                ("Technique", fb.techniqueScore, UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 1)),
                ("Power", fb.powerScore, UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1)),
                ("Balance", fb.balanceScore, UIColor(red: 0.0, green: 0.85, blue: 0.45, alpha: 1))
            ]

            for (i, sub) in subScores.enumerated() {
                let x = margin + CGFloat(i) * (subWidth + 20)
                let labelAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16, weight: .bold),
                    .foregroundColor: sub.2.withAlphaComponent(0.8)
                ]
                sub.0.draw(at: CGPoint(x: x, y: y), withAttributes: labelAttrs)

                let valAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 42, weight: .black),
                    .foregroundColor: UIColor.white
                ]
                "\(sub.1)".draw(at: CGPoint(x: x, y: y + 22), withAttributes: valAttrs)
            }
            y += 90

            // Summary
            let summaryAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.6)
            ]
            let summaryRect = CGRect(x: margin, y: y, width: size.width - margin * 2, height: 120)
            fb.plainSummary.draw(in: summaryRect, withAttributes: summaryAttrs)

            // Watermark
            let wmAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.2)
            ]
            let wm = "Generated by AIHomeRun"
            let wmSize = wm.size(withAttributes: wmAttrs)
            wm.draw(at: CGPoint(x: size.width - margin - wmSize.width, y: size.height - 40),
                    withAttributes: wmAttrs)
        }
    }

    // MARK: - Key Frame Extraction

    /// Extract a key frame image from a video at a specific time.
    static func extractKeyFrame(from videoURL: URL, atTime: Double = 0.5) async -> UIImage? {
        let asset = AVAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 1280, height: 1280)

        let time = CMTime(seconds: atTime, preferredTimescale: 600)
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    // MARK: - PDF Drawing Helpers

    private static func drawHeader(yOffset: CGFloat, margin: CGFloat, contentWidth: CGFloat, date: Date) -> CGFloat {
        var y = yOffset

        // Title
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .black),
            .foregroundColor: UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 1.0)
        ]
        "AIHomeRun".draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)

        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.gray
        ]
        "Analysis Report".draw(at: CGPoint(x: margin + 130, y: y + 6), withAttributes: subAttrs)

        // Date (right-aligned)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateStr = dateFormatter.string(from: date)
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        let dateSize = dateStr.size(withAttributes: dateAttrs)
        dateStr.draw(at: CGPoint(x: margin + contentWidth - dateSize.width, y: y + 6),
                    withAttributes: dateAttrs)

        y += 30

        // Separator line
        let linePath = UIBezierPath()
        linePath.move(to: CGPoint(x: margin, y: y))
        linePath.addLine(to: CGPoint(x: margin + contentWidth, y: y))
        UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 0.5).setStroke()
        linePath.lineWidth = 2
        linePath.stroke()

        return y + 12
    }

    private static func drawScoreSection(yOffset: CGFloat, margin: CGFloat, contentWidth: CGFloat, feedback: Feedback, data: ReportData) -> CGFloat {
        var y = yOffset

        // Player info
        if let name = data.playerName {
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: UIColor.darkGray
            ]
            name.draw(at: CGPoint(x: margin, y: y), withAttributes: nameAttrs)
            y += 18
        }

        if let age = data.playerAge {
            let ageAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            "Age \(age) · \(data.analysisResult.actionType.capitalized)".draw(
                at: CGPoint(x: margin, y: y), withAttributes: ageAttrs)
            y += 20
        }

        // Big score
        let scoreStr = "\(feedback.overallScore)"
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 48, weight: .black),
            .foregroundColor: scoreUIColor(for: feedback.grade)
        ]
        scoreStr.draw(at: CGPoint(x: margin, y: y), withAttributes: scoreAttrs)

        // Grade next to score
        let gradeAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: scoreUIColor(for: feedback.grade).withAlphaComponent(0.6)
        ]
        feedback.grade.draw(at: CGPoint(x: margin + 80, y: y + 16), withAttributes: gradeAttrs)

        y += 58
        return y
    }

    private static func drawSubScores(yOffset: CGFloat, margin: CGFloat, contentWidth: CGFloat, feedback: Feedback) -> CGFloat {
        var y = yOffset

        let sectionTitle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor.gray
        ]
        "SCORES".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionTitle)
        y += 18

        let scores = [
            ("Technique", feedback.techniqueScore, UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 1)),
            ("Power", feedback.powerScore, UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1)),
            ("Balance", feedback.balanceScore, UIColor(red: 0.0, green: 0.85, blue: 0.45, alpha: 1))
        ]

        let barWidth = (contentWidth - 20) / 3
        for (i, score) in scores.enumerated() {
            let x = margin + CGFloat(i) * (barWidth + 10)

            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: score.2
            ]
            score.0.draw(at: CGPoint(x: x, y: y), withAttributes: labelAttrs)

            let valAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .black),
                .foregroundColor: UIColor.black
            ]
            "\(score.1)".draw(at: CGPoint(x: x, y: y + 14), withAttributes: valAttrs)

            // Score bar
            let barRect = CGRect(x: x, y: y + 38, width: barWidth - 10, height: 4)
            UIColor(white: 0.9, alpha: 1).setFill()
            UIBezierPath(roundedRect: barRect, cornerRadius: 2).fill()

            let fillWidth = (barWidth - 10) * CGFloat(score.1) / 100.0
            let fillRect = CGRect(x: x, y: y + 38, width: fillWidth, height: 4)
            score.2.setFill()
            UIBezierPath(roundedRect: fillRect, cornerRadius: 2).fill()
        }

        return y + 52
    }

    private static func drawBiomechanics(yOffset: CGFloat, margin: CGFloat, contentWidth: CGFloat, metrics: Metrics) -> CGFloat {
        var y = yOffset

        let sectionTitle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor.gray
        ]
        "BIOMECHANICS".draw(at: CGPoint(x: margin, y: y), withAttributes: sectionTitle)
        y += 18

        let metricItems: [(String, String)] = [
            ("Peak Wrist Speed", metrics.peakWristSpeed.map { String(format: "%.1f m/s", $0) } ?? "N/A"),
            ("Hip-Shoulder Separation", metrics.hipShoulderSeparation.map { String(format: "%.0f\u{00B0}", $0) } ?? "N/A"),
            ("Follow-Through", metrics.followThrough.map { $0 ? "Yes" : "No" } ?? "N/A"),
            ("Elbow Angle", metrics.jointAngles?.elbowAngle.map { String(format: "%.0f\u{00B0}", $0) } ?? "N/A"),
            ("Knee Bend", metrics.jointAngles?.kneeBend.map { String(format: "%.0f\u{00B0}", $0) } ?? "N/A")
        ]

        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: UIColor.darkGray
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .bold),
            .foregroundColor: UIColor.black
        ]

        for item in metricItems {
            item.0.draw(at: CGPoint(x: margin, y: y), withAttributes: labelAttrs)
            let valSize = item.1.size(withAttributes: valueAttrs)
            item.1.draw(at: CGPoint(x: margin + contentWidth - valSize.width, y: y), withAttributes: valueAttrs)
            y += 16
        }

        return y + 8
    }

    private static func drawStrengthsImprovements(yOffset: CGFloat, margin: CGFloat, contentWidth: CGFloat, feedback: Feedback) -> CGFloat {
        var y = yOffset

        let halfWidth = (contentWidth - 16) / 2

        // Strengths
        if !feedback.strengths.isEmpty {
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: UIColor(red: 0.0, green: 0.7, blue: 0.35, alpha: 1)
            ]
            "STRENGTHS".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttrs)

            let itemAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]

            var sy = y + 16
            for item in feedback.strengths.prefix(4) {
                let bullet = "\u{2022} \(item)"
                let rect = CGRect(x: margin, y: sy, width: halfWidth, height: 30)
                bullet.draw(in: rect, withAttributes: itemAttrs)
                sy += 14
            }
        }

        // Improvements
        if !feedback.improvements.isEmpty {
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1)
            ]
            "IMPROVEMENTS".draw(at: CGPoint(x: margin + halfWidth + 16, y: y), withAttributes: headerAttrs)

            let itemAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]

            var iy = y + 16
            for item in feedback.improvements.prefix(4) {
                let bullet = "\u{2022} \(item)"
                let rect = CGRect(x: margin + halfWidth + 16, y: iy, width: halfWidth, height: 30)
                bullet.draw(in: rect, withAttributes: itemAttrs)
                iy += 14
            }
        }

        let maxItems = max(feedback.strengths.prefix(4).count, feedback.improvements.prefix(4).count)
        return y + 16 + CGFloat(maxItems) * 14 + 12
    }

    private static func drawDrill(yOffset: CGFloat, margin: CGFloat, contentWidth: CGFloat, drill: DrillInfo) -> CGFloat {
        var y = yOffset

        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1)
        ]
        "RECOMMENDED DRILL".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttrs)
        y += 16

        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        drill.name.draw(at: CGPoint(x: margin, y: y), withAttributes: nameAttrs)
        y += 16

        let descAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        let descRect = CGRect(x: margin, y: y, width: contentWidth, height: 40)
        drill.description.draw(in: descRect, withAttributes: descAttrs)
        y += 30

        if let reps = drill.reps {
            let repsAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1)
            ]
            reps.draw(at: CGPoint(x: margin, y: y), withAttributes: repsAttrs)
            y += 16
        }

        return y + 8
    }

    private static func drawFooter(pageHeight: CGFloat, margin: CGFloat, contentWidth: CGFloat) {
        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: UIColor.lightGray
        ]
        let footer = "Generated by AIHomeRun · AI-Powered Baseball Coaching"
        let footerSize = footer.size(withAttributes: footerAttrs)
        footer.draw(at: CGPoint(x: margin + (contentWidth - footerSize.width) / 2,
                                y: pageHeight - margin + 10),
                   withAttributes: footerAttrs)
    }

    private static func scoreUIColor(for grade: String) -> UIColor {
        switch grade {
        case "A+", "A": return UIColor(red: 0.0, green: 0.85, blue: 0.45, alpha: 1)
        case "B":       return UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 1)
        case "C":       return UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1)
        default:        return UIColor(red: 0.95, green: 0.25, blue: 0.25, alpha: 1)
        }
    }
}
