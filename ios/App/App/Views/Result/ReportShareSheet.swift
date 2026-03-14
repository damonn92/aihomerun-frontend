import SwiftUI

// MARK: - Report Share Sheet

/// Generates and shares PDF/image reports from analysis results.
struct ReportShareSheet: View {
    let result: AnalysisResult
    let videoURL: URL?
    let playerAge: Int?

    @State private var isGenerating = false
    @State private var reportPDFData: Data?
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var exportFormat: ExportFormat = .pdf

    enum ExportFormat: String, CaseIterable {
        case pdf = "PDF Report"
        case image = "Share Image"

        var icon: String {
            switch self {
            case .pdf: return "doc.richtext"
            case .image: return "photo"
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.hrBlue)
                Text("Export Report")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
            }

            // Format picker
            HStack(spacing: 8) {
                ForEach(ExportFormat.allCases, id: \.self) { format in
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            exportFormat = format
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: format.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(format.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(exportFormat == format ? Color.white : Color.primary.opacity(0.55))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(exportFormat == format ? Color.hrBlue : Color.hrSurface)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }

            // Preview
            reportPreview

            // Generate & Share button
            Button {
                Task { await generateAndShare() }
            } label: {
                HStack(spacing: 8) {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Text(isGenerating ? "Generating..." : "Generate & Share")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    LinearGradient(
                        colors: [Color.hrBlue, Color(red: 0.04, green: 0.36, blue: 0.80)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .opacity(isGenerating ? 0.7 : 1.0)
            }
            .buttonStyle(.plain)
            .disabled(isGenerating)
        }
        .padding(16)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hrStroke, lineWidth: 1)
        )
        .sheet(isPresented: $showShareSheet) {
            ActivityViewControllerRepresentable(activityItems: shareItems)
        }
    }

    // MARK: - Preview

    private var reportPreview: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Score circle
                ZStack {
                    Circle()
                        .fill(gradeColor(result.feedback.grade).opacity(0.14))
                        .frame(width: 48, height: 48)
                    Text("\(result.feedback.overallScore)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(gradeColor(result.feedback.grade))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Score: \(result.feedback.overallScore) (\(result.feedback.grade))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("Tech \(result.feedback.techniqueScore) · Power \(result.feedback.powerScore) · Balance \(result.feedback.balanceScore)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.55))
                    Text("\(result.feedback.strengths.count) strengths · \(result.feedback.improvements.count) improvements")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.45))
                }
                Spacer()
            }
            .padding(12)
            .background(Color.hrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    // MARK: - Generate

    private func generateAndShare() async {
        isGenerating = true

        // Extract key frame
        var keyFrame: UIImage?
        if let url = videoURL {
            keyFrame = await ReportExportService.extractKeyFrame(from: url)
        }

        let reportData = ReportExportService.ReportData(
            analysisResult: result,
            keyFrameImage: keyFrame,
            videoURL: videoURL,
            playerName: nil,
            playerAge: playerAge,
            date: Date()
        )

        switch exportFormat {
        case .pdf:
            let pdfData = ReportExportService.generatePDF(from: reportData)
            reportPDFData = pdfData

            // Save to temp file for sharing
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("AIHomeRun_Report_\(Date().timeIntervalSince1970).pdf")
            try? pdfData.write(to: tempURL)
            shareItems = [tempURL]

        case .image:
            let image = ReportExportService.generateShareImage(from: reportData)
            shareImage = image
            shareItems = [image]
        }

        isGenerating = false
        showShareSheet = true
    }

    // MARK: - Helpers

    private func gradeColor(_ grade: String) -> Color {
        switch grade {
        case "A+", "A": return .hrGreen
        case "B":       return .hrBlue
        case "C":       return .hrOrange
        default:        return .hrRed
        }
    }
}

// MARK: - UIActivityViewController Representable

struct ActivityViewControllerRepresentable: UIViewControllerRepresentable {
    let activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems,
                                  applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
