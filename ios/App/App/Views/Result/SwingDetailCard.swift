import SwiftUI

/// Expandable per-swing breakdown card for a session.
/// Shows each swing in a compact row that expands to reveal full metrics on tap.
/// The best swing is highlighted with a crown icon.
struct SwingDetailCard: View {
    let swings: [SwingEvent]
    @State private var expandedSwingId: UUID?
    @State private var appeared = false

    private var bestSwingId: UUID? {
        swings.max(by: { ($0.swingScore ?? 0) < ($1.swingScore ?? 0) })?.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Swing Breakdown", systemImage: "list.bullet.rectangle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary.opacity(0.55))
                    .textCase(.uppercase)
                    .tracking(0.7)

                Spacer()

                Text("\(swings.count) swings")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.4))
            }

            // Swing rows
            ForEach(Array(swings.enumerated()), id: \.element.id) { index, swing in
                swingRow(swing, index: index + 1)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(
                        .spring(duration: 0.45).delay(Double(index) * 0.05 + 0.1),
                        value: appeared
                    )
            }
        }
        .hrCard()
        .onAppear {
            withAnimation(.spring(duration: 0.4)) {
                appeared = true
            }
        }
    }

    // MARK: - Swing Row

    private func swingRow(_ swing: SwingEvent, index: Int) -> some View {
        let quality = swingQuality(swing)
        let isBest = swing.id == bestSwingId
        let isExpanded = expandedSwingId == swing.id

        return VStack(spacing: 0) {
            // Compact row
            Button {
                withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                    expandedSwingId = isExpanded ? nil : swing.id
                }
            } label: {
                HStack(spacing: 10) {
                    // Swing number + crown
                    ZStack {
                        Circle()
                            .fill(quality.color.opacity(0.12))
                            .frame(width: 32, height: 32)

                        if isBest {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.hrGold)
                                .offset(y: -18)
                        }

                        Text("#\(index)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(quality.color)
                    }

                    // Speed
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 3) {
                            Text(String(format: "%.1f", swing.barrelSpeedMPH ?? swing.handSpeedMPH))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("mph")
                                .font(.system(size: 9))
                                .foregroundStyle(.primary.opacity(0.4))
                        }
                        Text(swing.barrelSpeedMPH != nil ? "Barrel Speed" : "Hand Speed")
                            .font(.system(size: 9))
                            .foregroundStyle(.primary.opacity(0.4))
                    }

                    Spacer()

                    // Score pill
                    if let score = swing.swingScore {
                        Text("\(score)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(quality.color)
                            .frame(width: 36)
                    }

                    // Impact indicator
                    if swing.impactDetected {
                        Text("HIT")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.hrGreen)
                            .clipShape(Capsule())
                    } else {
                        Text("MISS")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.primary.opacity(0.3))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Capsule())
                    }

                    // Chevron
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.3))
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            // Expanded detail
            if isExpanded {
                expandedDetail(swing)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            // Divider (except last)
            if swing.id != swings.last?.id {
                Divider().background(Color.hrDivider)
            }
        }
    }

    // MARK: - Expanded Detail

    private func expandedDetail(_ swing: SwingEvent) -> some View {
        let quality = swingQuality(swing)

        return VStack(spacing: 10) {
            // Primary metrics row
            HStack(spacing: 0) {
                detailMetric("Duration", value: String(format: "%.0f", swing.swingDurationMS), unit: "ms")
                Spacer()
                detailMetric("Peak Accel", value: String(format: "%.1f", swing.peakAccelerationG), unit: "G")
                Spacer()
                detailMetric("Rotation", value: String(format: "%.0f", swing.rotationRateDPS), unit: "dps")
                if let angle = swing.attackAngleDegrees {
                    Spacer()
                    detailMetric("Attack Angle", value: String(format: "%.1f", angle), unit: "deg")
                }
            }

            // Advanced metrics row (if available)
            let hasAdvanced = swing.snapScore != nil || swing.powerTransferEfficiency != nil
                || swing.kineticChainScore != nil || swing.connectionScore != nil
            if hasAdvanced {
                HStack(spacing: 0) {
                    if let snap = swing.snapScore {
                        detailMetric("Snap", value: String(format: "%.0f", snap), unit: "/100")
                        Spacer()
                    }
                    if let power = swing.powerTransferEfficiency {
                        detailMetric("Power Xfer", value: String(format: "%.0f", power), unit: "%")
                        Spacer()
                    }
                    if let kinetic = swing.kineticChainScore {
                        detailMetric("Kinetic Chain", value: String(format: "%.0f", kinetic), unit: "/100")
                        Spacer()
                    }
                    if let conn = swing.connectionScore {
                        detailMetric("Connection", value: String(format: "%.0f", conn), unit: "/100")
                    }
                }
            }

            if let ttc = swing.timeToContactMS {
                HStack(spacing: 0) {
                    detailMetric("Time to Contact", value: String(format: "%.0f", ttc), unit: "ms")
                    Spacer()
                    if let plane = swing.swingPlaneAngle {
                        detailMetric("Swing Plane", value: String(format: "%.1f", plane), unit: "deg")
                        Spacer()
                    }
                    if let load = swing.loadTimeMS {
                        detailMetric("Load Time", value: String(format: "%.0f", load), unit: "ms")
                    }
                }
            }
        }
        .padding(12)
        .background(quality.color.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(quality.color.opacity(0.12), lineWidth: 1)
        )
        .padding(.bottom, 8)
    }

    private func detailMetric(_ label: String, value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(unit)
                    .font(.system(size: 8))
                    .foregroundStyle(.primary.opacity(0.4))
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.primary.opacity(0.45))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    // MARK: - Quality

    private func swingQuality(_ swing: SwingEvent) -> MetricGaugeView.MetricQuality {
        let score = swing.swingScore ?? Int(swing.handSpeedMPH * 3)
        switch score {
        case 80...: return .excellent
        case 60..<80: return .good
        case 40..<60: return .moderate
        default: return .needsWork
        }
    }
}

#Preview {
    ScrollView {
        SwingDetailCard(swings: [
            SwingEvent(handSpeedMPH: 18.2, peakAccelerationG: 12.5, timeToContactMS: 175,
                       attackAngleDegrees: 8.5, swingDurationMS: 185, impactDetected: true,
                       rotationRateDPS: 1250, rotationalAcceleration: 1100, swingScore: 78,
                       barrelSpeedMPH: 48.2, powerTransferEfficiency: 72, snapScore: 81,
                       kineticChainScore: 75, connectionScore: 70),
            SwingEvent(handSpeedMPH: 16.8, peakAccelerationG: 11.2, timeToContactMS: 195,
                       attackAngleDegrees: 12.1, swingDurationMS: 210, impactDetected: false,
                       rotationRateDPS: 1100, rotationalAcceleration: 950, swingScore: 65,
                       barrelSpeedMPH: 44.8, powerTransferEfficiency: 65, snapScore: 68,
                       kineticChainScore: 62),
            SwingEvent(handSpeedMPH: 19.5, peakAccelerationG: 13.8, timeToContactMS: 162,
                       attackAngleDegrees: 6.2, swingDurationMS: 172, impactDetected: true,
                       rotationRateDPS: 1380, rotationalAcceleration: 1250, swingScore: 88,
                       barrelSpeedMPH: 52.1, powerTransferEfficiency: 85, snapScore: 90,
                       kineticChainScore: 84, connectionScore: 82),
            SwingEvent(handSpeedMPH: 17.5, peakAccelerationG: 12.0, timeToContactMS: 188,
                       attackAngleDegrees: 9.8, swingDurationMS: 195, impactDetected: true,
                       rotationRateDPS: 1180, rotationalAcceleration: 1020, swingScore: 72,
                       barrelSpeedMPH: 46.5, powerTransferEfficiency: 70, snapScore: 74),
        ])
        .padding()
    }
    .background(Color.hrBg)
}
