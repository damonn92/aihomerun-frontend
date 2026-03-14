import SwiftUI

// MARK: - Circular Gauge for individual metrics (Blast-style)

/// A compact circular gauge that shows a metric value with color-coded quality indicator.
/// Inspired by Blast Baseball's metric cards with green/yellow/red quality indicators.
struct MetricGaugeView: View {
    let title: String
    let value: String
    let unit: String
    let fraction: Double          // 0.0–1.0 for the arc fill
    let quality: MetricQuality
    var icon: String? = nil
    var size: CGFloat = 64

    enum MetricQuality {
        case excellent, good, moderate, needsWork

        var color: Color {
            switch self {
            case .excellent:  return Color.hrGreen
            case .good:       return Color.hrBlue
            case .moderate:   return Color.hrOrange
            case .needsWork:  return Color.hrRed
            }
        }

        var label: String {
            switch self {
            case .excellent:  return "Excellent"
            case .good:       return "Good"
            case .moderate:   return "Fair"
            case .needsWork:  return "Work On"
            }
        }
    }

    @State private var animatedFraction: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background arc
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(quality.color.opacity(0.12), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(135))

                // Foreground arc
                Circle()
                    .trim(from: 0, to: animatedFraction * 0.75)
                    .stroke(
                        AngularGradient(
                            colors: [quality.color.opacity(0.5), quality.color],
                            center: .center,
                            startAngle: .degrees(135),
                            endAngle: .degrees(135 + 270 * animatedFraction)
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(135))

                // Value
                VStack(spacing: 0) {
                    Text(value)
                        .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text(unit)
                        .font(.system(size: size * 0.14))
                        .foregroundStyle(.primary.opacity(0.45))
                }
            }
            .frame(width: size, height: size)

            // Title + icon
            HStack(spacing: 3) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 9))
                        .foregroundStyle(quality.color)
                }
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            // Quality pill
            Text(quality.label)
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(quality.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(quality.color.opacity(0.12))
                .clipShape(Capsule())
        }
        .onAppear {
            withAnimation(.spring(duration: 1.0, bounce: 0.2).delay(0.2)) {
                animatedFraction = fraction
            }
        }
    }
}

// MARK: - Horizontal Bar Metric

/// A horizontal bar gauge showing a value with reference range.
/// Used for metrics like elbow angle, hip-shoulder separation.
struct MetricBarView: View {
    let label: String
    let value: Double
    let unit: String
    let range: ClosedRange<Double>   // Full display range
    let idealRange: ClosedRange<Double>  // "Green zone"
    let icon: String

    private var normalizedValue: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0.5 }
        return (value - range.lowerBound) / span
    }

    private var quality: MetricGaugeView.MetricQuality {
        if idealRange.contains(value) { return .excellent }
        let lowerDist = abs(value - idealRange.lowerBound)
        let upperDist = abs(value - idealRange.upperBound)
        let dist = min(lowerDist, upperDist)
        let idealSpan = idealRange.upperBound - idealRange.lowerBound
        if dist < idealSpan * 0.5 { return .good }
        if dist < idealSpan { return .moderate }
        return .needsWork
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .foregroundStyle(quality.color)
                        .frame(width: 16)
                    Text(label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.7))
                }

                Spacer()

                HStack(spacing: 3) {
                    Text(String(format: value == value.rounded() ? "%.0f" : "%.1f", value))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text(unit)
                        .font(.system(size: 10))
                        .foregroundStyle(.primary.opacity(0.45))
                }
            }

            // Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Full track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 6)

                    // Ideal zone highlight
                    let idealStart = (idealRange.lowerBound - range.lowerBound) / (range.upperBound - range.lowerBound)
                    let idealEnd = (idealRange.upperBound - range.lowerBound) / (range.upperBound - range.lowerBound)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.hrGreen.opacity(0.12))
                        .frame(width: geo.size.width * (idealEnd - idealStart), height: 6)
                        .offset(x: geo.size.width * idealStart)

                    // Value indicator
                    Circle()
                        .fill(quality.color)
                        .frame(width: 10, height: 10)
                        .shadow(color: quality.color.opacity(0.4), radius: 3)
                        .offset(x: geo.size.width * min(1, max(0, normalizedValue)) - 5)
                }
            }
            .frame(height: 10)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Plane Efficiency Gauge (Blast On-Plane style)

/// A semicircular gauge specifically for bat plane efficiency, matching Blast Baseball's
/// on-plane efficiency visualization style.
struct PlaneEfficiencyGaugeView: View {
    let efficiency: Double   // 0–100
    let consistency: Double? // 0–100, optional

    @State private var animatedEfficiency: Double = 0

    private var quality: MetricGaugeView.MetricQuality {
        switch efficiency {
        case 80...100: return .excellent
        case 60..<80:  return .good
        case 40..<60:  return .moderate
        default:       return .needsWork
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Label("Bat Plane Analysis", systemImage: "lines.measurement.horizontal")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary.opacity(0.55))
                    .textCase(.uppercase)
                    .tracking(0.7)
                Spacer()
            }

            HStack(spacing: 20) {
                // Main gauge
                VStack(spacing: 4) {
                    ZStack {
                        // Background semicircle
                        SemiCircle()
                            .stroke(Color.primary.opacity(0.08), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 120, height: 65)

                        // Colored fill
                        SemiCircle()
                            .trim(from: 0, to: animatedEfficiency / 100.0)
                            .stroke(
                                LinearGradient(
                                    colors: [quality.color.opacity(0.6), quality.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 120, height: 65)

                        // Value
                        VStack(spacing: 0) {
                            Spacer()
                            Text(String(format: "%.0f", animatedEfficiency))
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(quality.color)
                            Text("%")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.primary.opacity(0.4))
                        }
                        .frame(height: 60)
                    }
                    .frame(width: 120, height: 65)

                    Text("On-Plane")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.6))
                }

                // Details column
                VStack(alignment: .leading, spacing: 10) {
                    // Quality indicator
                    HStack(spacing: 6) {
                        Circle()
                            .fill(quality.color)
                            .frame(width: 8, height: 8)
                        Text(quality.label)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(quality.color)
                    }

                    // Plane efficiency detail
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Plane Efficiency")
                            .font(.system(size: 10))
                            .foregroundStyle(.primary.opacity(0.45))
                        ProgressView(value: efficiency, total: 100)
                            .tint(quality.color)
                    }

                    // Bat path consistency
                    if let consistency {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Path Consistency")
                                .font(.system(size: 10))
                                .foregroundStyle(.primary.opacity(0.45))
                            ProgressView(value: consistency, total: 100)
                                .tint(consistencyColor(consistency))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .hrCard()
        .onAppear {
            withAnimation(.spring(duration: 1.2, bounce: 0.15).delay(0.3)) {
                animatedEfficiency = efficiency
            }
        }
    }

    private func consistencyColor(_ v: Double) -> Color {
        switch v {
        case 75...100: return .hrGreen
        case 50..<75:  return .hrBlue
        case 25..<50:  return .hrOrange
        default:       return .hrRed
        }
    }
}

/// Upper-half semicircle shape for gauge backgrounds
struct SemiCircle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addArc(
                center: CGPoint(x: rect.midX, y: rect.maxY),
                radius: rect.width / 2,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack {
            MetricGaugeView(
                title: "Wrist Speed",
                value: "18.5",
                unit: "px/f",
                fraction: 0.74,
                quality: .good,
                icon: "bolt.fill"
            )
            MetricGaugeView(
                title: "Hip-Shoulder",
                value: "32",
                unit: "deg",
                fraction: 0.85,
                quality: .excellent,
                icon: "arrow.triangle.2.circlepath"
            )
            MetricGaugeView(
                title: "Balance",
                value: "0.85",
                unit: "",
                fraction: 0.85,
                quality: .excellent,
                icon: "figure.stand"
            )
        }

        PlaneEfficiencyGaugeView(efficiency: 82.5, consistency: 71.3)

        MetricBarView(
            label: "Elbow Angle",
            value: 95,
            unit: "°",
            range: 60...150,
            idealRange: 90...110,
            icon: "angle"
        )
        .padding(.horizontal)
    }
    .padding()
    .background(Color.hrBg)
}
