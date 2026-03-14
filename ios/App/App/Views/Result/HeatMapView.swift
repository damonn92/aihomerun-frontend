import SwiftUI

/// Strike zone heat map showing where the batter's attack angles cluster.
/// Uses a 3x3 grid representing zones of the strike zone, with color intensity
/// based on swing frequency. Attack angle and swing plane data are used to
/// estimate the zone for each swing.
struct HeatMapView: View {
    let swings: [SwingEvent]
    @State private var appeared = false

    // Zone labels for the 3x3 grid (row-major: top-left to bottom-right)
    private static let zoneLabels = [
        "Up-In",    "Up-Mid",    "Up-Away",
        "Mid-In",   "Middle",    "Mid-Away",
        "Low-In",   "Low-Mid",   "Low-Away"
    ]

    // MARK: - Zone Classification

    /// Maps each swing to a zone index (0-8) based on attack angle and swing plane.
    /// Attack angle determines vertical zone (high/mid/low).
    /// Swing plane determines horizontal zone (inside/middle/outside).
    private var zoneCounts: [Int] {
        var counts = Array(repeating: 0, count: 9)

        for swing in swings {
            let angle = swing.attackAngleDegrees ?? 10.0  // default mid
            let plane = swing.swingPlaneAngle ?? 0.0      // default center

            // Vertical: attack angle -> row
            // High angle (>15) = upper zone, mid (5-15) = middle, low (<5) = lower
            let row: Int
            if angle > 15 { row = 0 }
            else if angle >= 5 { row = 1 }
            else { row = 2 }

            // Horizontal: swing plane -> column
            // Negative plane = inside, zero = middle, positive = outside
            let col: Int
            if plane < -8 { col = 0 }
            else if plane <= 8 { col = 1 }
            else { col = 2 }

            counts[row * 3 + col] += 1
        }

        return counts
    }

    private var maxCount: Int {
        zoneCounts.max() ?? 1
    }

    private var totalClassified: Int {
        zoneCounts.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Label("Strike Zone Heat Map", systemImage: "square.grid.3x3.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary.opacity(0.55))
                    .textCase(.uppercase)
                    .tracking(0.7)

                Spacer()

                Text("\(totalClassified) swings mapped")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.4))
            }

            // Heat map grid
            HStack(spacing: 0) {
                // Left axis label
                Text("Inside")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.35))
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                    .frame(width: 14)

                VStack(spacing: 0) {
                    // Top axis label
                    Text("High")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.35))
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 4)

                    // 3x3 grid
                    VStack(spacing: 3) {
                        ForEach(0..<3, id: \.self) { row in
                            HStack(spacing: 3) {
                                ForEach(0..<3, id: \.self) { col in
                                    let index = row * 3 + col
                                    zoneCell(
                                        count: zoneCounts[index],
                                        label: Self.zoneLabels[index],
                                        index: index
                                    )
                                }
                            }
                        }
                    }
                    .padding(3)
                    .background(Color.primary.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )

                    // Bottom axis label
                    Text("Low")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.35))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }

                // Right axis label
                Text("Outside")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.35))
                    .rotationEffect(.degrees(90))
                    .fixedSize()
                    .frame(width: 14)
            }

            // Color legend
            HStack(spacing: 12) {
                Spacer()
                legendItem(label: "Cold", color: coldColor)
                legendItem(label: "Warm", color: warmColor)
                legendItem(label: "Hot", color: hotColor)
                Spacer()
            }

            // Summary insight
            if let hotZone = hotZoneInsight {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.hrOrange)
                    Text(hotZone)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary.opacity(0.65))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.hrOrange.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .hrCard()
        .onAppear {
            withAnimation(.spring(duration: 0.6)) {
                appeared = true
            }
        }
    }

    // MARK: - Zone Cell

    private func zoneCell(count: Int, label: String, index: Int) -> some View {
        let fraction = maxCount > 0 ? Double(count) / Double(maxCount) : 0
        let cellColor = heatColor(fraction: fraction)

        return ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(cellColor.opacity(appeared ? (count > 0 ? 0.15 + fraction * 0.55 : 0.03) : 0))
                .animation(.spring(duration: 0.5).delay(Double(index) * 0.04), value: appeared)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(cellColor.opacity(count > 0 ? 0.3 : 0.06), lineWidth: 1)

            VStack(spacing: 2) {
                Text("\(count)")
                    .font(.system(size: count > 0 ? 18 : 14, weight: .bold, design: .rounded))
                    .foregroundStyle(count > 0 ? cellColor : .primary.opacity(0.15))

                Text(label)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(count > 0 ? Color.primary.opacity(0.5) : Color.primary.opacity(0.2))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1.0, contentMode: .fit)
    }

    // MARK: - Heat Color

    private var coldColor: Color { Color(red: 0.2, green: 0.5, blue: 1.0) }
    private var warmColor: Color { Color.hrOrange }
    private var hotColor: Color { Color.hrRed }

    private func heatColor(fraction: Double) -> Color {
        if fraction <= 0 { return .primary }
        if fraction < 0.33 { return coldColor }
        if fraction < 0.66 { return warmColor }
        return hotColor
    }

    // MARK: - Legend

    private func legendItem(label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.6))
                .frame(width: 12, height: 12)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.primary.opacity(0.45))
        }
    }

    // MARK: - Hot Zone Insight

    private var hotZoneInsight: String? {
        guard !swings.isEmpty else { return nil }
        let counts = zoneCounts
        guard let maxIdx = counts.enumerated().max(by: { $0.element < $1.element })?.offset,
              counts[maxIdx] > 0 else { return nil }

        let zoneName = Self.zoneLabels[maxIdx]
        let pct = Int(Double(counts[maxIdx]) / Double(totalClassified) * 100)
        return "Hot zone: \(zoneName) (\(pct)% of swings)"
    }
}

#Preview {
    ScrollView {
        HeatMapView(swings: [
            SwingEvent(handSpeedMPH: 18.2, peakAccelerationG: 12.5, attackAngleDegrees: 8.5,
                       swingDurationMS: 185, impactDetected: true, rotationRateDPS: 1250,
                       swingPlaneAngle: -5),
            SwingEvent(handSpeedMPH: 16.8, peakAccelerationG: 11.2, attackAngleDegrees: 12.1,
                       swingDurationMS: 210, impactDetected: false, rotationRateDPS: 1100,
                       swingPlaneAngle: 3),
            SwingEvent(handSpeedMPH: 19.5, peakAccelerationG: 13.8, attackAngleDegrees: 6.2,
                       swingDurationMS: 172, impactDetected: true, rotationRateDPS: 1380,
                       swingPlaneAngle: -2),
            SwingEvent(handSpeedMPH: 17.5, peakAccelerationG: 12.0, attackAngleDegrees: 9.8,
                       swingDurationMS: 195, impactDetected: true, rotationRateDPS: 1180,
                       swingPlaneAngle: 0),
            SwingEvent(handSpeedMPH: 18.8, peakAccelerationG: 12.8, attackAngleDegrees: 7.5,
                       swingDurationMS: 180, impactDetected: true, rotationRateDPS: 1300,
                       swingPlaneAngle: 1),
            SwingEvent(handSpeedMPH: 15.2, peakAccelerationG: 10.5, attackAngleDegrees: 18.0,
                       swingDurationMS: 225, impactDetected: false, rotationRateDPS: 950,
                       swingPlaneAngle: 12),
        ])
        .padding()
    }
    .background(Color.hrBg)
}
