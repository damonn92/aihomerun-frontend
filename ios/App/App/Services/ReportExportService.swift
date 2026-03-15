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

    /// Generate a tall shareable image with full report content (single long image).
    static func generateShareImage(from data: ReportData) -> UIImage {
        let imgWidth: CGFloat = 1080
        let margin: CGFloat = 60
        let contentWidth = imgWidth - margin * 2
        let fb = data.analysisResult.feedback
        let metrics = data.analysisResult.metrics

        // --- Colors ---
        let bgColor = UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1.0)
        let cardBg = UIColor(white: 1.0, alpha: 0.06)
        let cardBgAlt = UIColor(white: 1.0, alpha: 0.04)
        let accentBlue = UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 1.0)
        let textWhite = UIColor.white
        let textDim = UIColor.white.withAlphaComponent(0.55)
        let textMuted = UIColor.white.withAlphaComponent(0.4)
        let dividerColor = UIColor.white.withAlphaComponent(0.08)
        let greenColor = UIColor(red: 0.0, green: 0.85, blue: 0.45, alpha: 1)
        let orangeColor = UIColor(red: 1.0, green: 0.58, blue: 0.0, alpha: 1)

        // --- Pre-calculate total height ---
        let totalHeight = shareImageTotalHeight(data: data, imgWidth: imgWidth, margin: margin, contentWidth: contentWidth)

        let size = CGSize(width: imgWidth, height: totalHeight)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)

            // === BACKGROUND ===
            bgColor.setFill()
            ctx.fill(rect)

            // Top gradient accent bar
            let barHeight: CGFloat = 6
            let gctx = UIGraphicsGetCurrentContext()!
            gctx.saveGState()
            gctx.addRect(CGRect(x: 0, y: 0, width: imgWidth, height: barHeight))
            gctx.clip()
            let gradColors: [CGColor] = [accentBlue.cgColor, UIColor(red: 0.4, green: 0.2, blue: 0.95, alpha: 1).cgColor]
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradColors as CFArray, locations: [0, 1])!
            gctx.drawLinearGradient(grad, start: .zero, end: CGPoint(x: imgWidth, y: 0), options: [])
            gctx.restoreGState()

            var y: CGFloat = barHeight + 36

            // === HEADER: Logo + Title + Date ===
            if let logo = loadAppLogo() {
                let logoSize: CGFloat = 52
                let logoRect = CGRect(x: margin, y: y, width: logoSize, height: logoSize)
                let ctx2 = UIGraphicsGetCurrentContext()!
                ctx2.saveGState()
                UIBezierPath(roundedRect: logoRect, cornerRadius: 12).addClip()
                logo.draw(in: logoRect)
                ctx2.restoreGState()

                let titleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 36, weight: .black),
                    .foregroundColor: textWhite
                ]
                "AIHomeRun".draw(at: CGPoint(x: margin + logoSize + 14, y: y + 2), withAttributes: titleAttrs)

                let subtitleAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16, weight: .medium),
                    .foregroundColor: accentBlue.withAlphaComponent(0.8)
                ]
                "Analysis Report".draw(at: CGPoint(x: margin + logoSize + 16, y: y + 38), withAttributes: subtitleAttrs)
            }
            y += 72

            // Date + Player info line
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            var infoStr = dateFormatter.string(from: data.date)
            if let name = data.playerName { infoStr += "  ·  \(name)" }
            if let age = data.playerAge { infoStr += "  ·  Age \(age)" }
            infoStr += "  ·  \(data.analysisResult.actionType.capitalized)"

            let infoAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: textDim
            ]
            infoStr.draw(at: CGPoint(x: margin, y: y), withAttributes: infoAttrs)
            y += 40

            // Divider
            dividerColor.setFill()
            UIBezierPath(rect: CGRect(x: margin, y: y, width: contentWidth, height: 1)).fill()
            y += 28

            // === SCORE HERO SECTION ===
            let scoreCardRect = CGRect(x: margin, y: y, width: contentWidth, height: 200)
            cardBg.setFill()
            UIBezierPath(roundedRect: scoreCardRect, cornerRadius: 20).fill()

            // Big score number (left side)
            let gradeColor = scoreUIColor(for: fb.grade)
            let scoreStr = "\(fb.overallScore)"
            let bigScoreAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 96, weight: .black),
                .foregroundColor: gradeColor
            ]
            let bigScoreSize = scoreStr.size(withAttributes: bigScoreAttrs)
            scoreStr.draw(at: CGPoint(x: margin + 36, y: y + (200 - bigScoreSize.height) / 2 - 8), withAttributes: bigScoreAttrs)

            // Grade label
            let gradeLabelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .bold),
                .foregroundColor: gradeColor.withAlphaComponent(0.6)
            ]
            fb.grade.draw(at: CGPoint(x: margin + 36 + bigScoreSize.width + 10, y: y + (200 - bigScoreSize.height) / 2 + 14), withAttributes: gradeLabelAttrs)

            // "/ 100" under score
            let outOfAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .medium),
                .foregroundColor: textMuted
            ]
            "/ 100".draw(at: CGPoint(x: margin + 42, y: y + (200 - bigScoreSize.height) / 2 + bigScoreSize.height - 8), withAttributes: outOfAttrs)

            // Sub-scores on right side (stacked vertically)
            let subScores: [(String, Int, UIColor)] = [
                ("Technique", fb.techniqueScore, accentBlue),
                ("Power", fb.powerScore, orangeColor),
                ("Balance", fb.balanceScore, greenColor)
            ]
            let subStartX = imgWidth / 2 + 40
            let subBarWidth = contentWidth - (subStartX - margin) - 36
            var subY = y + 28
            for sub in subScores {
                let labelAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 17, weight: .bold),
                    .foregroundColor: sub.2
                ]
                sub.0.draw(at: CGPoint(x: subStartX, y: subY), withAttributes: labelAttrs)

                let valAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .black),
                    .foregroundColor: textWhite
                ]
                let valStr = "\(sub.1)"
                let valSize = valStr.size(withAttributes: valAttrs)
                valStr.draw(at: CGPoint(x: subStartX + subBarWidth - valSize.width, y: subY), withAttributes: valAttrs)

                // Progress bar
                let barY = subY + 26
                let barH: CGFloat = 6
                UIColor.white.withAlphaComponent(0.08).setFill()
                UIBezierPath(roundedRect: CGRect(x: subStartX, y: barY, width: subBarWidth, height: barH), cornerRadius: 3).fill()
                sub.2.setFill()
                UIBezierPath(roundedRect: CGRect(x: subStartX, y: barY, width: subBarWidth * CGFloat(sub.1) / 100, height: barH), cornerRadius: 3).fill()

                subY += 50
            }
            y += 200 + 28

            // === KEY FRAME IMAGE ===
            if let image = data.keyFrameImage {
                let maxImgH: CGFloat = 520
                let imgAspect = image.size.width / image.size.height
                let imgW = min(contentWidth, maxImgH * imgAspect)
                let imgH = imgW / imgAspect
                let imgX = margin + (contentWidth - imgW) / 2

                let imgRect = CGRect(x: imgX, y: y, width: imgW, height: imgH)
                let ctx2 = UIGraphicsGetCurrentContext()!
                ctx2.saveGState()
                UIBezierPath(roundedRect: imgRect, cornerRadius: 16).addClip()
                image.draw(in: imgRect)
                ctx2.restoreGState()

                // Subtle border
                UIColor.white.withAlphaComponent(0.1).setStroke()
                let borderPath = UIBezierPath(roundedRect: imgRect, cornerRadius: 16)
                borderPath.lineWidth = 1.5
                borderPath.stroke()

                y += imgH + 28
            }

            // === SUMMARY ===
            let summaryHeaderAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15, weight: .bold),
                .foregroundColor: textMuted
            ]
            "SUMMARY".draw(at: CGPoint(x: margin, y: y), withAttributes: summaryHeaderAttrs)
            y += 28

            let summaryAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.75)
            ]
            let summaryH = textHeight(fb.plainSummary, width: contentWidth, attributes: summaryAttrs)
            fb.plainSummary.draw(in: CGRect(x: margin, y: y, width: contentWidth, height: summaryH), withAttributes: summaryAttrs)
            y += summaryH + 28

            // Divider
            dividerColor.setFill()
            UIBezierPath(rect: CGRect(x: margin, y: y, width: contentWidth, height: 1)).fill()
            y += 24

            // === BIOMECHANICS TABLE ===
            let bioHeaderAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15, weight: .bold),
                .foregroundColor: textMuted
            ]
            "BIOMECHANICS".draw(at: CGPoint(x: margin, y: y), withAttributes: bioHeaderAttrs)
            y += 32

            let metricItems: [(String, String)] = [
                ("Peak Wrist Speed", metrics.peakWristSpeed.map { String(format: "%.1f m/s", $0) } ?? "N/A"),
                ("Hip-Shoulder Separation", metrics.hipShoulderSeparation.map { String(format: "%.0f°", $0) } ?? "N/A"),
                ("Follow-Through", metrics.followThrough.map { $0 ? "Yes" : "No" } ?? "N/A"),
                ("Elbow Angle", metrics.jointAngles?.elbowAngle.map { String(format: "%.0f°", $0) } ?? "N/A"),
                ("Knee Bend", metrics.jointAngles?.kneeBend.map { String(format: "%.0f°", $0) } ?? "N/A")
            ]

            let metricLabelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 19, weight: .medium),
                .foregroundColor: textDim
            ]
            let metricValAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 19, weight: .bold),
                .foregroundColor: textWhite
            ]

            for (index, item) in metricItems.enumerated() {
                // Alternating row background
                if index % 2 == 0 {
                    cardBgAlt.setFill()
                    UIBezierPath(roundedRect: CGRect(x: margin, y: y - 8, width: contentWidth, height: 40), cornerRadius: 8).fill()
                }
                item.0.draw(at: CGPoint(x: margin + 12, y: y), withAttributes: metricLabelAttrs)
                let valSize = item.1.size(withAttributes: metricValAttrs)
                item.1.draw(at: CGPoint(x: margin + contentWidth - valSize.width - 12, y: y), withAttributes: metricValAttrs)
                y += 42
            }
            y += 20

            // Divider
            dividerColor.setFill()
            UIBezierPath(rect: CGRect(x: margin, y: y, width: contentWidth, height: 1)).fill()
            y += 24

            // === STRENGTHS & IMPROVEMENTS (two columns) ===
            let halfWidth = (contentWidth - 30) / 2

            let sectionItemAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .regular),
                .foregroundColor: UIColor.white.withAlphaComponent(0.75)
            ]

            // Strengths header (left)
            if !fb.strengths.isEmpty {
                let sHeaderAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 15, weight: .bold),
                    .foregroundColor: greenColor
                ]
                // Green dot
                greenColor.withAlphaComponent(0.5).setFill()
                UIBezierPath(ovalIn: CGRect(x: margin, y: y + 4, width: 8, height: 8)).fill()
                "STRENGTHS".draw(at: CGPoint(x: margin + 14, y: y), withAttributes: sHeaderAttrs)
            }

            // Improvements header (right)
            if !fb.improvements.isEmpty {
                let iHeaderAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 15, weight: .bold),
                    .foregroundColor: orangeColor
                ]
                let rightX = margin + halfWidth + 30
                orangeColor.withAlphaComponent(0.5).setFill()
                UIBezierPath(ovalIn: CGRect(x: rightX, y: y + 4, width: 8, height: 8)).fill()
                "IMPROVEMENTS".draw(at: CGPoint(x: rightX + 14, y: y), withAttributes: iHeaderAttrs)
            }
            y += 32

            // Draw items
            var leftY = y
            for item in fb.strengths.prefix(5) {
                let bullet = "• \(item)"
                let h = textHeight(bullet, width: halfWidth - 12, attributes: sectionItemAttrs)
                bullet.draw(in: CGRect(x: margin + 4, y: leftY, width: halfWidth - 12, height: h), withAttributes: sectionItemAttrs)
                leftY += h + 10
            }

            var rightY = y
            let rightX = margin + halfWidth + 30
            for item in fb.improvements.prefix(5) {
                let bullet = "• \(item)"
                let h = textHeight(bullet, width: halfWidth - 12, attributes: sectionItemAttrs)
                bullet.draw(in: CGRect(x: rightX + 4, y: rightY, width: halfWidth - 12, height: h), withAttributes: sectionItemAttrs)
                rightY += h + 10
            }
            y = max(leftY, rightY) + 20

            // Divider
            dividerColor.setFill()
            UIBezierPath(rect: CGRect(x: margin, y: y, width: contentWidth, height: 1)).fill()
            y += 24

            // === DRILL RECOMMENDATION ===
            if let drill = fb.drill {
                // Card background
                let drillCardH = shareImageDrillHeight(drill: drill, contentWidth: contentWidth, margin: margin)
                let drillCardRect = CGRect(x: margin, y: y, width: contentWidth, height: drillCardH)
                accentBlue.withAlphaComponent(0.08).setFill()
                UIBezierPath(roundedRect: drillCardRect, cornerRadius: 16).fill()

                // Left accent bar
                accentBlue.withAlphaComponent(0.6).setFill()
                UIBezierPath(roundedRect: CGRect(x: margin, y: y, width: 4, height: drillCardH), cornerRadius: 2).fill()

                let innerX = margin + 24
                let innerW = contentWidth - 48
                var dy = y + 20

                let drillHeaderAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                    .foregroundColor: accentBlue
                ]
                "RECOMMENDED DRILL".draw(at: CGPoint(x: innerX, y: dy), withAttributes: drillHeaderAttrs)
                dy += 26

                let drillNameAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: textWhite
                ]
                let nameH = textHeight(drill.name, width: innerW, attributes: drillNameAttrs)
                drill.name.draw(in: CGRect(x: innerX, y: dy, width: innerW, height: nameH), withAttributes: drillNameAttrs)
                dy += nameH + 8

                let drillDescAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18, weight: .regular),
                    .foregroundColor: textDim
                ]
                let descH = textHeight(drill.description, width: innerW, attributes: drillDescAttrs)
                drill.description.draw(in: CGRect(x: innerX, y: dy, width: innerW, height: descH), withAttributes: drillDescAttrs)
                dy += descH + 12

                if let reps = drill.reps {
                    let repsAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 15, weight: .bold),
                        .foregroundColor: accentBlue
                    ]
                    let repsSize = reps.size(withAttributes: repsAttrs)
                    let badgeRect = CGRect(x: innerX, y: dy, width: repsSize.width + 20, height: repsSize.height + 10)
                    accentBlue.withAlphaComponent(0.15).setFill()
                    UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeRect.height / 2).fill()
                    reps.draw(at: CGPoint(x: innerX + 10, y: dy + 5), withAttributes: repsAttrs)
                }

                y += drillCardH + 28
            }

            // === FOOTER ===
            dividerColor.setFill()
            UIBezierPath(rect: CGRect(x: margin, y: y, width: contentWidth, height: 1)).fill()
            y += 20

            // Footer with logo
            if let logo = loadAppLogo() {
                let fLogoSize: CGFloat = 20
                let fLogoRect = CGRect(x: imgWidth / 2 - 120, y: y, width: fLogoSize, height: fLogoSize)
                let ctx2 = UIGraphicsGetCurrentContext()!
                ctx2.saveGState()
                UIBezierPath(roundedRect: fLogoRect, cornerRadius: 4).addClip()
                logo.draw(in: fLogoRect)
                ctx2.restoreGState()

                let footerAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 15, weight: .medium),
                    .foregroundColor: textMuted
                ]
                "Generated by AIHomeRun".draw(at: CGPoint(x: imgWidth / 2 - 120 + fLogoSize + 8, y: y + 1), withAttributes: footerAttrs)
            }
        }
    }

    // MARK: - Share Image Height Calculation

    private static func shareImageDrillHeight(drill: DrillInfo, contentWidth: CGFloat, margin: CGFloat) -> CGFloat {
        let innerW = contentWidth - 48
        let nameAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 22, weight: .bold)]
        let descAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 18, weight: .regular)]
        let nameH = textHeight(drill.name, width: innerW, attributes: nameAttrs)
        let descH = textHeight(drill.description, width: innerW, attributes: descAttrs)
        return 20 + 26 + nameH + 8 + descH + 12 + (drill.reps != nil ? 36 : 0) + 20
    }

    private static func shareImageTotalHeight(data: ReportData, imgWidth: CGFloat, margin: CGFloat, contentWidth: CGFloat) -> CGFloat {
        let fb = data.analysisResult.feedback
        var h: CGFloat = 6 + 36 // top bar + padding
        h += 72 // header
        h += 40 // info line + gap
        h += 28 // divider
        h += 200 + 28 // score hero

        // Key frame
        if let image = data.keyFrameImage {
            let maxImgH: CGFloat = 520
            let imgAspect = image.size.width / image.size.height
            let imgW = min(contentWidth, maxImgH * imgAspect)
            let imgH = imgW / imgAspect
            h += imgH + 28
        }

        // Summary
        let summaryAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .regular)
        ]
        h += 28 + textHeight(fb.plainSummary, width: contentWidth, attributes: summaryAttrs) + 28

        // Divider + biomechanics header
        h += 24 + 32
        h += CGFloat(5) * 42 + 20 // 5 metric rows

        // Divider + strengths/improvements
        h += 24 + 32

        let halfWidth = (contentWidth - 30) / 2
        let sectionItemAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .regular)
        ]
        var leftH: CGFloat = 0
        for item in fb.strengths.prefix(5) {
            leftH += textHeight("• \(item)", width: halfWidth - 12, attributes: sectionItemAttrs) + 10
        }
        var rightH: CGFloat = 0
        for item in fb.improvements.prefix(5) {
            rightH += textHeight("• \(item)", width: halfWidth - 12, attributes: sectionItemAttrs) + 10
        }
        h += max(leftH, rightH) + 20

        // Divider + drill
        h += 24
        if let drill = fb.drill {
            h += shareImageDrillHeight(drill: drill, contentWidth: contentWidth, margin: margin) + 28
        }

        // Footer
        h += 24 + 30 + 40 // divider + footer + bottom padding

        return h
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

    private static func loadAppLogo() -> UIImage? {
        // Try regular image asset first, then fall back to loading from bundle
        if let img = UIImage(named: "AppLogo") { return img }
        if let url = Bundle.main.url(forResource: "AppIcon-512@2x", withExtension: "png"),
           let img = UIImage(contentsOfFile: url.path) { return img }
        return nil
    }

    private static func drawHeader(yOffset: CGFloat, margin: CGFloat, contentWidth: CGFloat, date: Date, pageWidth: CGFloat) -> CGFloat {
        var y = yOffset

        // Logo (app icon)
        let logoSize: CGFloat = 30
        var titleX = margin
        if let logo = loadAppLogo() {
            let logoRect = CGRect(x: margin, y: y - 2, width: logoSize, height: logoSize)
            let ctx = UIGraphicsGetCurrentContext()!
            ctx.saveGState()
            UIBezierPath(roundedRect: logoRect, cornerRadius: 7).addClip()
            logo.draw(in: logoRect)
            ctx.restoreGState()
            titleX = margin + logoSize + 8
        }

        // Title "AIHomeRun"
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 20, weight: .black),
            .foregroundColor: UIColor(red: 0.08, green: 0.47, blue: 0.98, alpha: 1.0)
        ]
        let titleStr = "AIHomeRun"
        titleStr.draw(at: CGPoint(x: titleX, y: y), withAttributes: titleAttrs)

        // "Analysis Report" — dynamically positioned after title text
        let titleSize = titleStr.size(withAttributes: titleAttrs)
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: UIColor(white: 0.55, alpha: 1)
        ]
        "Analysis Report".draw(at: CGPoint(x: titleX + titleSize.width + 6, y: y + 6), withAttributes: subAttrs)

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
        if let logo = loadAppLogo() {
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
