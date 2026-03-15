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

    // MARK: - Text Height Helper

    /// Calculate the actual height that text will occupy when drawn in a constrained rect.
    private static func textHeight(_ text: String, width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let nsStr = text as NSString
        let boundingRect = nsStr.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return ceil(boundingRect.height)
    }

    // MARK: - PDF Generation (Multi-Page)

    /// Generate a multi-page PDF report from analysis data.
    static func generatePDF(from data: ReportData) -> Data {
        let pageWidth: CGFloat = 612    // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 48
        let contentWidth = pageWidth - margin * 2
        let maxY = pageHeight - margin  // Bottom boundary

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            context.beginPage()

            var yOffset: CGFloat = margin
            let fb = data.analysisResult.feedback
            let metrics = data.analysisResult.metrics

            // === PAGE BACKGROUND ===
            drawPageBackground(pageWidth: pageWidth, pageHeight: pageHeight)

            // === HEADER WITH LOGO ===
            yOffset = drawHeader(yOffset: yOffset, margin: margin, contentWidth: contentWidth, date: data.date, pageWidth: pageWidth)

            // === SCORE HERO ===
            yOffset = drawScoreSection(yOffset: yOffset, margin: margin, contentWidth: contentWidth, feedback: fb, data: data)

            // === KEY FRAME IMAGE ===
            if let image = data.keyFrameImage {
                yOffset += 16
                let maxImgHeight: CGFloat = 200
                let imgAspect = image.size.width / image.size.height
                let imgWidth = min(contentWidth * 0.55, maxImgHeight * imgAspect)
                let imgHeight = imgWidth / imgAspect
                let imgX = margin + (contentWidth - imgWidth) / 2

                // Image border/shadow
                let imgRect = CGRect(x: imgX, y: yOffset, width: imgWidth, height: imgHeight)
                let shadowRect = imgRect.insetBy(dx: -1, dy: -1)
                UIColor(white: 0.85, alpha: 1).setStroke()
                let border = UIBezierPath(roundedRect: shadowRect, cornerRadius: 8)
                border.lineWidth = 1
                border.stroke()

                // Clip and draw image
                let clipPath = UIBezierPath(roundedRect: imgRect, cornerRadius: 8)
                let ctx = UIGraphicsGetCurrentContext()!
                ctx.saveGState()
                clipPath.addClip()
                image.draw(in: imgRect)
                ctx.restoreGState()

                yOffset += imgHeight + 18
            }

            // === SUB-SCORES ===
            yOffset = drawSubScores(yOffset: yOffset, margin: margin, contentWidth: contentWidth, feedback: fb)

            // === BIOMECHANICS ===
            yOffset = drawBiomechanics(yOffset: yOffset, margin: margin, contentWidth: contentWidth, metrics: metrics)

            // === STRENGTHS & IMPROVEMENTS ===
            // Check if we need a new page
            let strengthsHeight = estimateStrengthsHeight(feedback: fb, contentWidth: contentWidth, margin: margin)
            if yOffset + strengthsHeight > maxY {
                drawFooter(pageHeight: pageHeight, margin: margin, contentWidth: contentWidth)
                context.beginPage()
                drawPageBackground(pageWidth: pageWidth, pageHeight: pageHeight)
                yOffset = margin + 20
            }
            yOffset = drawStrengthsImprovements(yOffset: yOffset, margin: margin, contentWidth: contentWidth, feedback: fb)

            // === DRILL RECOMMENDATION ===
            if let drill = fb.drill {
                let drillHeight = estimateDrillHeight(drill: drill, contentWidth: contentWidth, margin: margin)
                if yOffset + drillHeight > maxY {
                    drawFooter(pageHeight: pageHeight, margin: margin, contentWidth: contentWidth)
                    context.beginPage()
                    drawPageBackground(pageWidth: pageWidth, pageHeight: pageHeight)
                    yOffset = margin + 20
                }
                yOffset = drawDrill(yOffset: yOffset, margin: margin, contentWidth: contentWidth, drill: drill)
            }

            // === FOOTER ===
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

            // Logo + Title
            if let logo = UIImage(named: "AppIcon-512@2x") ?? UIImage(named: "AppLogo") {
                let logoSize: CGFloat = 44
                logo.draw(in: CGRect(x: margin, y: y, width: logoSize, height: logoSize))

                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 32, weight: .black),
                    .foregroundColor: UIColor.white
                ]
                "AIHomeRun".draw(at: CGPoint(x: margin + logoSize + 12, y: y + 4), withAttributes: titleAttrs)
            } else {
                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 32, weight: .black),
                    .foregroundColor: UIColor.white
                ]
                "AIHomeRun Report".draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
            }
            y += 56

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

            // Logo watermark
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

    private static func drawPageBackground(pageWidth: CGFloat, pageHeight: CGFloat) {
        // White page background
        UIColor.white.setFill()
        UIBezierPath(rect: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)).fill()
    }

    private static func drawHeader(yOffset: CGFloat, margin: CGFloat, contentWidth: CGFloat, date: Date, pageWidth: CGFloat) -> CGFloat {
        var y = yOffset

        // Logo (app icon)
        let logoSize: CGFloat = 32
        if let logo = UIImage(named: "AppIcon-512@2x") ?? UIImage(named: "AppLogo") {
            let logoRect = CGRect(x: margin, y: y - 4, width: logoSize, height: logoSize)
            // Draw rounded logo
            let ctx = UIGraphicsGetCurrentContext()!
            ctx.saveGState()
            UIBezierPath(roundedRect: logoRect, cornerRadius: 7).addClip()
            logo.draw(in: logoRect)
            ctx.restoreGState()
        }

        // Title next to logo
        let titleX = margin + logoSize + 10
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .black),
            .foregroundColor: UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 1.0)
        ]
        "AIHomeRun".draw(at: CGPoint(x: titleX, y: y), withAttributes: titleAttrs)

        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor(white: 0.55, alpha: 1)
        ]
        "Analysis Report".draw(at: CGPoint(x: titleX + 108, y: y + 5), withAttributes: subAttrs)

        // Date (right-aligned)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let dateStr = dateFormatter.string(from: date)
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor(white: 0.50, alpha: 1)
        ]
        let dateSize = dateStr.size(withAttributes: dateAttrs)
        dateStr.draw(at: CGPoint(x: margin + contentWidth - dateSize.width, y: y + 5),
                    withAttributes: dateAttrs)

        y += 34

        // Gradient separator line
        let lineRect = CGRect(x: margin, y: y, width: contentWidth, height: 2.5)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.saveGState()
        let colors: [CGColor] = [
            UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 1.0).cgColor,
            UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 0.2).cgColor
        ]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
        ctx.addRect(lineRect)
        ctx.clip()
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: margin, y: y),
                               end: CGPoint(x: margin + contentWidth, y: y),
                               options: [])
        ctx.restoreGState()

        return y + 16
    }

    private static func drawScoreSection(yOffset: CGFloat, margin: CGFloat, contentWidth: CGFloat, feedback: Feedback, data: ReportData) -> CGFloat {
        var y = yOffset

        // Player info
        if let name = data.playerName {
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13, weight: .semibold),
                .foregroundColor: UIColor(white: 0.30, alpha: 1)
            ]
            name.draw(at: CGPoint(x: margin, y: y), withAttributes: nameAttrs)
            y += 18
        }

        if let age = data.playerAge {
            let ageAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                .foregroundColor: UIColor(white: 0.50, alpha: 1)
            ]
            "Age \(age) \u{00B7} \(data.analysisResult.actionType.capitalized)".draw(
                at: CGPoint(x: margin, y: y), withAttributes: ageAttrs)
            y += 20
        }

        // Big score
        let scoreStr = "\(feedback.overallScore)"
        let scoreAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 52, weight: .black),
            .foregroundColor: scoreUIColor(for: feedback.grade)
        ]
        scoreStr.draw(at: CGPoint(x: margin, y: y), withAttributes: scoreAttrs)

        // Grade next to score
        let scoreStrSize = scoreStr.size(withAttributes: scoreAttrs)
        let gradeAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: scoreUIColor(for: feedback.grade).withAlphaComponent(0.5)
        ]
        feedback.grade.draw(at: CGPoint(x: margin + scoreStrSize.width + 8, y: y + 18), withAttributes: gradeAttrs)

        y += 60
        return y
    }

    private static func drawSubScores(yOffset: CGFloat, margin: CGFloat, contentWidth: CGFloat, feedback: Feedback) -> CGFloat {
        var y = yOffset

        let sectionTitle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: UIColor(white: 0.50, alpha: 1)
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

            // Label
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
                .foregroundColor: score.2
            ]
            score.0.draw(at: CGPoint(x: x, y: y), withAttributes: labelAttrs)

            // Value
            let valAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .black),
                .foregroundColor: UIColor(white: 0.15, alpha: 1)
            ]
            "\(score.1)".draw(at: CGPoint(x: x, y: y + 14), withAttributes: valAttrs)

            // Background bar
            let barRect = CGRect(x: x, y: y + 42, width: barWidth - 10, height: 5)
            UIColor(white: 0.92, alpha: 1).setFill()
            UIBezierPath(roundedRect: barRect, cornerRadius: 2.5).fill()

            // Filled bar
            let fillWidth = (barWidth - 10) * CGFloat(score.1) / 100.0
            let fillRect = CGRect(x: x, y: y + 42, width: fillWidth, height: 5)
            score.2.setFill()
            UIBezierPath(roundedRect: fillRect, cornerRadius: 2.5).fill()
        }

        return y + 58
    }

    private static func drawBiomechanics(yOffset: CGFloat, margin: CGFloat, contentWidth: CGFloat, metrics: Metrics) -> CGFloat {
        var y = yOffset

        // Section divider
        UIColor(white: 0.90, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: margin, y: y, width: contentWidth, height: 0.5)).fill()
        y += 12

        let sectionTitle: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: UIColor(white: 0.50, alpha: 1)
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
            .foregroundColor: UIColor(white: 0.35, alpha: 1)
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .bold),
            .foregroundColor: UIColor(white: 0.15, alpha: 1)
        ]

        for (index, item) in metricItems.enumerated() {
            // Alternating row background
            if index % 2 == 0 {
                UIColor(white: 0.97, alpha: 1).setFill()
                UIBezierPath(rect: CGRect(x: margin, y: y - 2, width: contentWidth, height: 16)).fill()
            }

            item.0.draw(at: CGPoint(x: margin + 4, y: y), withAttributes: labelAttrs)
            let valSize = item.1.size(withAttributes: valueAttrs)
            item.1.draw(at: CGPoint(x: margin + contentWidth - valSize.width - 4, y: y), withAttributes: valueAttrs)
            y += 17
        }

        return y + 10
    }

    // MARK: - Strengths & Improvements (FIXED text overlap)

    private static func estimateStrengthsHeight(feedback: Feedback, contentWidth: CGFloat, margin: CGFloat) -> CGFloat {
        let halfWidth = (contentWidth - 24) / 2
        let itemAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9.5, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]

        var leftHeight: CGFloat = 24 // header
        for item in feedback.strengths.prefix(4) {
            let h = textHeight("\u{2022} \(item)", width: halfWidth - 8, attributes: itemAttrs)
            leftHeight += h + 6
        }

        var rightHeight: CGFloat = 24 // header
        for item in feedback.improvements.prefix(4) {
            let h = textHeight("\u{2022} \(item)", width: halfWidth - 8, attributes: itemAttrs)
            rightHeight += h + 6
        }

        return max(leftHeight, rightHeight) + 16
    }

    private static func drawStrengthsImprovements(yOffset: CGFloat, margin: CGFloat, contentWidth: CGFloat, feedback: Feedback) -> CGFloat {
        var y = yOffset

        // Section divider
        UIColor(white: 0.90, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: margin, y: y, width: contentWidth, height: 0.5)).fill()
        y += 12

        let halfWidth = (contentWidth - 24) / 2

        let itemAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9.5, weight: .regular),
            .foregroundColor: UIColor(white: 0.30, alpha: 1)
        ]

        // ---- LEFT COLUMN: Strengths ----
        var leftMaxY = y
        if !feedback.strengths.isEmpty {
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: UIColor(red: 0.0, green: 0.7, blue: 0.35, alpha: 1)
            ]
            "STRENGTHS".draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttrs)

            // Green accent dot
            let dotRect = CGRect(x: margin + 80, y: y + 3, width: 6, height: 6)
            UIColor(red: 0.0, green: 0.7, blue: 0.35, alpha: 0.4).setFill()
            UIBezierPath(ovalIn: dotRect).fill()

            var sy = y + 20
            for item in feedback.strengths.prefix(4) {
                let bullet = "\u{2022} \(item)"
                let h = textHeight(bullet, width: halfWidth - 8, attributes: itemAttrs)
                let rect = CGRect(x: margin + 4, y: sy, width: halfWidth - 8, height: h)
                bullet.draw(in: rect, withAttributes: itemAttrs)
                sy += h + 6
            }
            leftMaxY = sy
        }

        // ---- RIGHT COLUMN: Improvements ----
        var rightMaxY = y
        if !feedback.improvements.isEmpty {
            let headerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1)
            ]
            let rightX = margin + halfWidth + 24
            "IMPROVEMENTS".draw(at: CGPoint(x: rightX, y: y), withAttributes: headerAttrs)

            // Orange accent dot
            let dotRect = CGRect(x: rightX + 106, y: y + 3, width: 6, height: 6)
            UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 0.4).setFill()
            UIBezierPath(ovalIn: dotRect).fill()

            var iy = y + 20
            for item in feedback.improvements.prefix(4) {
                let bullet = "\u{2022} \(item)"
                let h = textHeight(bullet, width: halfWidth - 8, attributes: itemAttrs)
                let rect = CGRect(x: rightX + 4, y: iy, width: halfWidth - 8, height: h)
                bullet.draw(in: rect, withAttributes: itemAttrs)
                iy += h + 6
            }
            rightMaxY = iy
        }

        return max(leftMaxY, rightMaxY) + 12
    }

    // MARK: - Drill Recommendation (FIXED text overlap)

    private static func estimateDrillHeight(drill: DrillInfo, contentWidth: CGFloat, margin: CGFloat) -> CGFloat {
        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold)
        ]
        let descAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]
        let nameH = textHeight(drill.name, width: contentWidth, attributes: nameAttrs)
        let descH = textHeight(drill.description, width: contentWidth, attributes: descAttrs)
        return 20 + nameH + 6 + descH + 6 + 20 + 24
    }

    private static func drawDrill(yOffset: CGFloat, margin: CGFloat, contentWidth: CGFloat, drill: DrillInfo) -> CGFloat {
        var y = yOffset

        // Section divider
        UIColor(white: 0.90, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: margin, y: y, width: contentWidth, height: 0.5)).fill()
        y += 12

        // Background card
        let cardTop = y - 4
        UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 0.05).setFill()
        UIBezierPath(roundedRect: CGRect(x: margin, y: cardTop, width: contentWidth, height: estimateDrillHeight(drill: drill, contentWidth: contentWidth - 24, margin: margin)),
                     cornerRadius: 8).fill()

        // Left accent bar
        UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 0.6).setFill()
        UIBezierPath(roundedRect: CGRect(x: margin, y: cardTop, width: 3, height: estimateDrillHeight(drill: drill, contentWidth: contentWidth - 24, margin: margin)),
                     cornerRadius: 1.5).fill()

        let innerMargin = margin + 12

        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .bold),
            .foregroundColor: UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 1)
        ]
        "RECOMMENDED DRILL".draw(at: CGPoint(x: innerMargin, y: y), withAttributes: headerAttrs)
        y += 18

        let nameAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor(white: 0.15, alpha: 1)
        ]
        let nameH = textHeight(drill.name, width: contentWidth - 24, attributes: nameAttrs)
        drill.name.draw(in: CGRect(x: innerMargin, y: y, width: contentWidth - 24, height: nameH), withAttributes: nameAttrs)
        y += nameH + 6

        let descAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor(white: 0.35, alpha: 1)
        ]
        let descH = textHeight(drill.description, width: contentWidth - 24, attributes: descAttrs)
        drill.description.draw(in: CGRect(x: innerMargin, y: y, width: contentWidth - 24, height: descH), withAttributes: descAttrs)
        y += descH + 8

        if let reps = drill.reps {
            // Reps badge
            let repsAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .bold),
                .foregroundColor: UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 1)
            ]
            let repsSize = reps.size(withAttributes: repsAttrs)
            let badgeRect = CGRect(x: innerMargin, y: y, width: repsSize.width + 14, height: repsSize.height + 6)

            UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 0.12).setFill()
            UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeRect.height / 2).fill()
            reps.draw(at: CGPoint(x: innerMargin + 7, y: y + 3), withAttributes: repsAttrs)
            y += badgeRect.height + 8
        }

        return y + 12
    }

    private static func drawFooter(pageHeight: CGFloat, margin: CGFloat, contentWidth: CGFloat) {
        let y = pageHeight - margin + 8

        // Separator line
        UIColor(white: 0.90, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: margin, y: y - 4, width: contentWidth, height: 0.5)).fill()

        // Logo icon (small)
        if let logo = UIImage(named: "AppIcon-512@2x") ?? UIImage(named: "AppLogo") {
            let logoSize: CGFloat = 14
            let ctx = UIGraphicsGetCurrentContext()!
            ctx.saveGState()
            let logoRect = CGRect(x: margin + (contentWidth - 200) / 2, y: y + 1, width: logoSize, height: logoSize)
            UIBezierPath(roundedRect: logoRect, cornerRadius: 3).addClip()
            logo.draw(in: logoRect)
            ctx.restoreGState()
        }

        let footerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8, weight: .medium),
            .foregroundColor: UIColor(white: 0.65, alpha: 1)
        ]
        let footer = "Generated by AIHomeRun \u{00B7} AI-Powered Baseball Coaching"
        let footerSize = footer.size(withAttributes: footerAttrs)
        footer.draw(at: CGPoint(x: margin + (contentWidth - footerSize.width) / 2 + 10,
                                y: y + 2),
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
