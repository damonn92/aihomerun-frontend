import SwiftUI

/// Professional radar / spider chart for visualizing multi-dimensional scores.
/// Inspired by Blast Baseball's PCR (Plane/Connection/Rotation) display.
struct RadarChartView: View {
    let axes: [RadarAxis]
    var size: CGFloat = 200
    var gridLevels: Int = 4
    var animated: Bool = true

    @State private var animationProgress: CGFloat = 0

    struct RadarAxis: Identifiable {
        let id = UUID()
        let label: String
        let value: Double   // 0–100
        let icon: String
        let color: Color
    }

    private var center: CGPoint { CGPoint(x: size / 2, y: size / 2) }
    private var radius: CGFloat { size / 2 - 32 }
    private var angleStep: Angle { .degrees(360.0 / Double(axes.count)) }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Grid rings
                ForEach(1...gridLevels, id: \.self) { level in
                    let frac = CGFloat(level) / CGFloat(gridLevels)
                    gridPolygon(fraction: frac)
                        .stroke(Color.primary.opacity(level == gridLevels ? 0.12 : 0.06),
                                lineWidth: level == gridLevels ? 1 : 0.5)
                }

                // Axis lines
                ForEach(0..<axes.count, id: \.self) { i in
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: point(for: i, fraction: 1.0))
                    }
                    .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                }

                // Filled data polygon
                dataPolygon
                    .fill(
                        LinearGradient(
                            colors: [Color.hrBlue.opacity(0.25), Color.hrGreen.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Data polygon outline
                dataPolygon
                    .stroke(
                        LinearGradient(
                            colors: [Color.hrBlue, Color.hrGreen],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )

                // Data points (dots) at each vertex
                ForEach(0..<axes.count, id: \.self) { i in
                    let p = point(for: i, fraction: axes[i].value / 100.0 * animationProgress)
                    Circle()
                        .fill(axes[i].color)
                        .frame(width: 8, height: 8)
                        .shadow(color: axes[i].color.opacity(0.6), radius: 4)
                        .position(p)
                }

                // Axis labels around the outside
                ForEach(0..<axes.count, id: \.self) { i in
                    let labelPoint = point(for: i, fraction: 1.22)
                    VStack(spacing: 2) {
                        Image(systemName: axes[i].icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(axes[i].color)
                        Text(axes[i].label)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.primary.opacity(0.7))
                        Text("\(Int(axes[i].value))")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(axes[i].color)
                    }
                    .position(labelPoint)
                }
            }
            .frame(width: size, height: size)
        }
        .onAppear {
            if animated {
                withAnimation(.spring(duration: 1.2, bounce: 0.2).delay(0.3)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
    }

    // MARK: - Geometry

    private func point(for index: Int, fraction: CGFloat) -> CGPoint {
        let angle = angleStep.radians * Double(index) - .pi / 2
        return CGPoint(
            x: center.x + radius * fraction * CGFloat(Foundation.cos(angle)),
            y: center.y + radius * fraction * CGFloat(Foundation.sin(angle))
        )
    }

    private func gridPolygon(fraction: CGFloat) -> Path {
        Path { path in
            for i in 0..<axes.count {
                let p = point(for: i, fraction: fraction)
                if i == 0 { path.move(to: p) }
                else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
    }

    private var dataPolygon: Path {
        Path { path in
            for i in 0..<axes.count {
                let frac = axes[i].value / 100.0 * animationProgress
                let p = point(for: i, fraction: frac)
                if i == 0 { path.move(to: p) }
                else { path.addLine(to: p) }
            }
            path.closeSubpath()
        }
    }
}

#Preview {
    RadarChartView(axes: [
        .init(label: "Technique", value: 82, icon: "figure.baseball", color: .hrBlue),
        .init(label: "Power",     value: 68, icon: "bolt.fill",       color: .hrOrange),
        .init(label: "Balance",   value: 75, icon: "figure.stand",    color: .hrGreen),
    ])
    .padding()
    .background(Color.hrBg)
}
