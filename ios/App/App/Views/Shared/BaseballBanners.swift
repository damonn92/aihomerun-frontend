import SwiftUI

// MARK: - BaseballHeroBanner
// Full-width hero for UploadView — top-down baseball diamond on a night field

struct BaseballHeroBanner: View {
    let greeting: String
    let subtitle: String
    @State private var ballRotation: Double = 0
    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Night sky gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.10, blue: 0.26),
                        Color(red: 0.03, green: 0.06, blue: 0.16)
                    ],
                    startPoint: .top, endPoint: .bottom
                )

                // Stars (deterministic positions)
                Canvas { ctx, sz in
                    let stars: [(Double, Double, Double)] = [
                        (0.04, 0.09, 1.1), (0.14, 0.04, 0.8), (0.23, 0.17, 0.9),
                        (0.34, 0.07, 0.6), (0.47, 0.13, 1.3), (0.59, 0.05, 0.8),
                        (0.71, 0.11, 0.7), (0.84, 0.08, 1.0), (0.91, 0.17, 0.9),
                        (0.10, 0.26, 0.5), (0.77, 0.22, 1.0), (0.53, 0.20, 0.6),
                        (0.29, 0.30, 0.5), (0.89, 0.29, 0.8), (0.63, 0.24, 0.6),
                    ]
                    for (xf, yf, r) in stars {
                        let rect = CGRect(
                            x: sz.width * xf - r, y: sz.height * yf - r,
                            width: r * 2, height: r * 2
                        )
                        ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.65)))
                    }
                }

                // Baseball diamond (top-down) — right side
                Canvas { ctx, sz in
                    let cx = sz.width * 0.73
                    let cy = sz.height * 0.56
                    let size: CGFloat = min(sz.height * 0.55, 88)

                    // Outfield grass oval
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: cx - size * 1.25, y: cy - size * 1.25,
                            width: size * 2.5, height: size * 2.5)),
                        with: .color(Color(red: 0.07, green: 0.20, blue: 0.09).opacity(0.75))
                    )

                    // Infield dirt diamond
                    var dirt = Path()
                    dirt.move(to: CGPoint(x: cx, y: cy - size * 0.72))
                    dirt.addLine(to: CGPoint(x: cx + size * 0.72, y: cy))
                    dirt.addLine(to: CGPoint(x: cx, y: cy + size * 0.72))
                    dirt.addLine(to: CGPoint(x: cx - size * 0.72, y: cy))
                    dirt.closeSubpath()
                    ctx.fill(dirt, with: .color(Color(red: 0.42, green: 0.28, blue: 0.15).opacity(0.70)))

                    // Inner grass square
                    var innerGrass = Path()
                    let ig = size * 0.46
                    innerGrass.move(to: CGPoint(x: cx, y: cy - ig))
                    innerGrass.addLine(to: CGPoint(x: cx + ig, y: cy))
                    innerGrass.addLine(to: CGPoint(x: cx, y: cy + ig))
                    innerGrass.addLine(to: CGPoint(x: cx - ig, y: cy))
                    innerGrass.closeSubpath()
                    ctx.fill(innerGrass, with: .color(Color(red: 0.08, green: 0.26, blue: 0.10).opacity(0.75)))

                    // Base paths (dashed)
                    let dash = StrokeStyle(lineWidth: 1.0, dash: [5, 4])
                    let corners: [(CGPoint, CGPoint)] = [
                        (CGPoint(x: cx, y: cy - size*0.72), CGPoint(x: cx + size*0.72, y: cy)),
                        (CGPoint(x: cx + size*0.72, y: cy), CGPoint(x: cx, y: cy + size*0.72)),
                        (CGPoint(x: cx, y: cy + size*0.72), CGPoint(x: cx - size*0.72, y: cy)),
                        (CGPoint(x: cx - size*0.72, y: cy), CGPoint(x: cx, y: cy - size*0.72)),
                    ]
                    for (a, b) in corners {
                        var p = Path(); p.move(to: a); p.addLine(to: b)
                        ctx.stroke(p, with: .color(.white.opacity(0.30)), style: dash)
                    }

                    // Pitcher's mound
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: cx - 5, y: cy - 5, width: 10, height: 10)),
                        with: .color(Color(red: 0.48, green: 0.32, blue: 0.18).opacity(0.90))
                    )

                    // Home plate
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: cx - 4, y: cy + size*0.68, width: 8, height: 8)),
                        with: .color(.white.opacity(0.80))
                    )

                    // Bases (1st, 2nd, 3rd)
                    let baseCoords: [(CGFloat, CGFloat)] = [
                        (cx + size*0.70, cy), (cx, cy - size*0.70), (cx - size*0.70, cy)
                    ]
                    for (bx, by) in baseCoords {
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: bx - 4, y: by - 4, width: 8, height: 8)),
                            with: .color(.white.opacity(0.85))
                        )
                    }

                    // Foul lines
                    let foulStyle = StrokeStyle(lineWidth: 0.8)
                    var fl1 = Path()
                    fl1.move(to: CGPoint(x: cx, y: cy + size*0.72))
                    fl1.addLine(to: CGPoint(x: cx - size*1.4, y: cy - size*0.22))
                    ctx.stroke(fl1, with: .color(.white.opacity(0.18)), style: foulStyle)
                    var fl2 = Path()
                    fl2.move(to: CGPoint(x: cx, y: cy + size*0.72))
                    fl2.addLine(to: CGPoint(x: cx + size*1.4, y: cy - size*0.22))
                    ctx.stroke(fl2, with: .color(.white.opacity(0.18)), style: foulStyle)

                    // Stadium light poles
                    let poles: [(CGFloat, CGFloat)] = [
                        (cx - size*0.18, cy - size*1.20),
                        (cx + size*0.18, cy - size*1.20),
                        (cx - size*1.15, cy + size*0.02),
                        (cx + size*1.15, cy + size*0.02),
                    ]
                    for (px, py) in poles {
                        var pole = Path()
                        pole.move(to: CGPoint(x: px, y: py + 16))
                        pole.addLine(to: CGPoint(x: px, y: py))
                        ctx.stroke(pole, with: .color(.white.opacity(0.28)), style: StrokeStyle(lineWidth: 1.5))
                        ctx.fill(
                            Path(roundedRect: CGRect(x: px - 5, y: py - 4, width: 10, height: 4), cornerRadius: 2),
                            with: .color(Color(red: 1.0, green: 0.95, blue: 0.70).opacity(0.60))
                        )
                    }
                }

                // Spinning baseball — upper-left area
                SpinningBaseball(rotation: ballRotation)
                    .frame(width: 36, height: 36)
                    .position(x: geo.size.width * 0.14, y: geo.size.height * 0.32)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.6), value: appeared)

                // Score ring decoration (top-right corner)
                ZStack {
                    Circle()
                        .stroke(Color.hrBlue.opacity(0.18), lineWidth: 3)
                        .frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0, to: appeared ? 0.72 : 0)
                        .stroke(Color.hrBlue.opacity(0.55),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 1.4, bounce: 0.2).delay(0.2), value: appeared)
                    Text("72")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.60))
                }
                .position(x: geo.size.width * 0.22, y: geo.size.height * 0.72)
                .opacity(appeared ? 0.70 : 0)

                // Bottom gradient fade
                LinearGradient(
                    colors: [.clear, Color.hrBg.opacity(0.45)],
                    startPoint: .init(x: 0.5, y: 0.45),
                    endPoint: .bottom
                )

                // Text overlay — left side
                VStack(spacing: 0) {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.50))
                        }
                        .padding(.leading, 20)
                        .padding(.bottom, 16)
                        Spacer()
                    }
                }
            }
            .onAppear {
                appeared = true
                withAnimation(.linear(duration: 9.0).repeatForever(autoreverses: false)) {
                    ballRotation = 360
                }
            }
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hrBlue.opacity(0.28), lineWidth: 1)
        )
    }
}

// MARK: - SpinningBaseball

struct SpinningBaseball: View {
    let rotation: Double

    var body: some View {
        ZStack {
            Image(systemName: "baseball.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color(red: 0.96, green: 0.94, blue: 0.88))
            Image(systemName: "baseball")
                .font(.system(size: 26))
                .foregroundStyle(Color(red: 0.80, green: 0.15, blue: 0.15))
        }
        .shadow(color: .white.opacity(0.3), radius: 4)
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - StadiumNightBanner
// Night stadium silhouette for RankingsView

struct StadiumNightBanner: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            // Deep night sky
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.18),
                    Color(red: 0.05, green: 0.08, blue: 0.26)
                ],
                startPoint: .top, endPoint: .bottom
            )

            // Stars
            Canvas { ctx, sz in
                let stars: [(Double, Double, Double)] = [
                    (0.04, 0.10, 1.0), (0.11, 0.18, 0.7), (0.19, 0.07, 1.2),
                    (0.31, 0.14, 0.8), (0.44, 0.04, 1.1), (0.54, 0.17, 0.6),
                    (0.64, 0.09, 1.1), (0.77, 0.05, 0.9), (0.87, 0.14, 1.0),
                    (0.93, 0.24, 0.7), (0.26, 0.28, 0.5), (0.70, 0.26, 0.7),
                    (0.48, 0.22, 0.6), (0.15, 0.32, 0.4), (0.82, 0.30, 0.5),
                ]
                for (xf, yf, r) in stars {
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: sz.width * xf - r, y: sz.height * yf - r,
                            width: r * 2, height: r * 2)),
                        with: .color(.white.opacity(0.70))
                    )
                }
            }

            // Stadium silhouette + field
            Canvas { ctx, sz in
                let floorY = sz.height * 0.76

                // Stadium bowl
                var bowl = Path()
                bowl.move(to: CGPoint(x: 0, y: sz.height))
                bowl.addLine(to: CGPoint(x: 0, y: floorY))
                bowl.addCurve(
                    to: CGPoint(x: sz.width * 0.50, y: floorY - sz.height * 0.32),
                    control1: CGPoint(x: sz.width * 0.14, y: floorY - sz.height * 0.24),
                    control2: CGPoint(x: sz.width * 0.34, y: floorY - sz.height * 0.32)
                )
                bowl.addCurve(
                    to: CGPoint(x: sz.width, y: floorY),
                    control1: CGPoint(x: sz.width * 0.66, y: floorY - sz.height * 0.32),
                    control2: CGPoint(x: sz.width * 0.86, y: floorY - sz.height * 0.24)
                )
                bowl.addLine(to: CGPoint(x: sz.width, y: sz.height))
                bowl.closeSubpath()
                ctx.fill(bowl, with: .color(Color(red: 0.07, green: 0.10, blue: 0.22)))

                // Field green glow
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: sz.width * 0.22, y: floorY - sz.height * 0.04,
                        width: sz.width * 0.56, height: sz.height * 0.16)),
                    with: .color(Color(red: 0.04, green: 0.52, blue: 0.12).opacity(0.45))
                )

                // Diamond on field
                let fc = CGPoint(x: sz.width * 0.50, y: floorY + sz.height * 0.04)
                let ds: CGFloat = 14
                var dia = Path()
                dia.move(to: CGPoint(x: fc.x, y: fc.y - ds))
                dia.addLine(to: CGPoint(x: fc.x + ds, y: fc.y))
                dia.addLine(to: CGPoint(x: fc.x, y: fc.y + ds))
                dia.addLine(to: CGPoint(x: fc.x - ds, y: fc.y))
                dia.closeSubpath()
                ctx.fill(dia, with: .color(Color(red: 0.40, green: 0.26, blue: 0.12).opacity(0.60)))

                // Light poles (4 poles)
                let poleData: [(Double, Double)] = [
                    (0.07, 0.12), (0.21, 0.04), (0.79, 0.04), (0.93, 0.12)
                ]
                for (xf, yf) in poleData {
                    let px = sz.width * xf
                    let topY = sz.height * yf
                    let botY = floorY + 2

                    // Pole shaft
                    var shaft = Path()
                    shaft.move(to: CGPoint(x: px, y: botY))
                    shaft.addLine(to: CGPoint(x: px, y: topY))
                    ctx.stroke(shaft, with: .color(.white.opacity(0.32)),
                               style: StrokeStyle(lineWidth: 2))

                    // Light bar
                    ctx.fill(
                        Path(roundedRect: CGRect(x: px - 9, y: topY - 5, width: 18, height: 5), cornerRadius: 2),
                        with: .color(Color(red: 1.0, green: 0.95, blue: 0.72).opacity(0.75))
                    )
                }

                // Crowd dots (3 rows)
                let crowdRows: [(Double, Int, Double, Double)] = [
                    (floorY - sz.height * 0.06, 34, 0.13, 0.87),
                    (floorY - sz.height * 0.12, 30, 0.18, 0.82),
                    (floorY - sz.height * 0.19, 24, 0.24, 0.76),
                ]
                let crowdColors: [Color] = [.hrRed, .hrBlue, .hrGold, .hrGreen, .hrOrange, .white]
                for (rowY, count, xStart, xEnd) in crowdRows {
                    let span = sz.width * (xEnd - xStart)
                    let step = span / CGFloat(count)
                    for i in 0..<count {
                        let dotX = sz.width * xStart + step * CGFloat(i) + step * 0.5
                        // Deterministic jitter using sine
                        let jitter = sin(Double(i) * 1.618 + rowY) * 2.5
                        let color = crowdColors[i % crowdColors.count]
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: dotX - 2, y: rowY + jitter - 2, width: 4, height: 4)),
                            with: .color(color.opacity(0.50))
                        )
                    }
                }
            }

            // Light beams from poles
            Canvas { ctx, sz in
                let fieldY = sz.height * 0.82
                let poleData: [(Double, Double)] = [
                    (0.07, 0.12), (0.21, 0.04), (0.79, 0.04), (0.93, 0.12)
                ]
                for (xf, yf) in poleData {
                    var beam = Path()
                    beam.move(to: CGPoint(x: sz.width * xf, y: sz.height * yf))
                    beam.addLine(to: CGPoint(x: sz.width * 0.38, y: fieldY))
                    beam.addLine(to: CGPoint(x: sz.width * 0.62, y: fieldY))
                    beam.closeSubpath()
                    ctx.fill(beam, with: .color(.white.opacity(0.022)))
                }
            }

            // Bottom fade
            LinearGradient(
                colors: [.clear, Color.hrBg.opacity(0.55)],
                startPoint: .init(x: 0.5, y: 0.52),
                endPoint: .bottom
            )

            // Overlay labels
            VStack(spacing: 0) {
                Spacer()
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Label("LEADERBOARD", systemImage: "trophy.fill")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Color.hrGold)
                            .tracking(1.5)
                        Text("See where you stand among all players")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.40))
                    }
                    .padding(.leading, 18)
                    .padding(.bottom, 14)

                    Spacer()

                    // Mini podium graphic
                    HStack(alignment: .bottom, spacing: 3) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(white: 0.58).opacity(0.65))
                            .frame(width: 16, height: 22)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.hrGold.opacity(0.80))
                            .frame(width: 16, height: 30)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(red: 0.78, green: 0.50, blue: 0.22).opacity(0.65))
                            .frame(width: 16, height: 17)
                    }
                    .padding(.trailing, 18)
                    .padding(.bottom, 14)
                }
            }
        }
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.hrBlue.opacity(0.22), lineWidth: 1)
        )
        .onAppear { appeared = true }
    }
}

// MARK: - CoachHeroBanner
// Full-width tech-themed header for AICoachView (replaces old coachBanner)

struct CoachHeroBanner: View {
    let sessionCount: Int
    @State private var pulse = false
    @State private var dataFlow = false

    var body: some View {
        ZStack {
            // Tech dark background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.08, blue: 0.22),
                    Color.hrCard
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            // Grid pattern
            Canvas { ctx, sz in
                let sp: CGFloat = 22
                var x: CGFloat = 0
                while x <= sz.width {
                    var p = Path(); p.move(to: .init(x: x, y: 0)); p.addLine(to: .init(x: x, y: sz.height))
                    ctx.stroke(p, with: .color(Color.hrBlue.opacity(0.07)), style: StrokeStyle(lineWidth: 0.5))
                    x += sp
                }
                var y: CGFloat = 0
                while y <= sz.height {
                    var p = Path(); p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: sz.width, y: y))
                    ctx.stroke(p, with: .color(Color.hrBlue.opacity(0.07)), style: StrokeStyle(lineWidth: 0.5))
                    y += sp
                }
            }

            HStack(spacing: 0) {
                // Pulsing AI avatar
                ZStack {
                    ForEach([54, 72, 90], id: \.self) { sz in
                        Circle()
                            .stroke(Color.hrBlue.opacity(pulse ? 0 : 0.22), lineWidth: 1.2)
                            .frame(width: CGFloat(sz), height: CGFloat(sz))
                            .scaleEffect(pulse ? 1.35 : 1.0)
                            .animation(
                                .easeOut(duration: 2.0)
                                .repeatForever(autoreverses: false)
                                .delay(Double(sz) * 0.008),
                                value: pulse
                            )
                    }
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.hrBlue.opacity(0.55), Color.hrBlue.opacity(0.22)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 52, height: 52)
                    Image("AICoachIcon")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .foregroundStyle(.white)
                }
                .frame(width: 100)
                .padding(.leading, 14)

                // Coach info
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text("Coach AI")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Circle()
                            .fill(Color.hrGreen)
                            .frame(width: 7, height: 7)
                        Text("Online")
                            .font(.caption)
                            .foregroundStyle(Color.hrGreen.opacity(0.85))
                    }

                    Text("Demo Mode · Responses are pre-written")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.40))

                    // Animated data bars
                    HStack(spacing: 3) {
                        let barHeights: [CGFloat] = [12, 20, 8, 24, 16, 20, 10, 18]
                        ForEach(0..<barHeights.count, id: \.self) { i in
                            let h = barHeights[i]
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.hrBlue.opacity(dataFlow ? 0.85 : 0.22))
                                .frame(width: 4, height: dataFlow ? h : h * 0.35)
                                .animation(
                                    .easeInOut(duration: 0.55)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.09),
                                    value: dataFlow
                                )
                        }
                        Text("AI")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.hrBlue.opacity(0.70))
                    }
                }

                Spacer()

                // Session count
                VStack(spacing: 2) {
                    Text("\(sessionCount)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(Color.hrBlue)
                    Text("sessions")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.32))
                        .tracking(0.3)
                }
                .padding(.trailing, 18)
            }
        }
        .frame(height: 88)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.white.opacity(0.07)),
            alignment: .bottom
        )
        .onAppear {
            pulse = true
            dataFlow = true
        }
    }
}

// MARK: - QuickStatsBar
// 3-column stat summary shown on UploadView dashboard

struct QuickStatsBar: View {
    let sessions: Int
    let bestScore: Int
    let avgScore: Int

    var body: some View {
        HStack(spacing: 0) {
            statCell(icon: "film.stack", value: "\(sessions)", label: "Sessions", color: .hrBlue)
            Divider().frame(height: 28).background(Color.white.opacity(0.10))
            statCell(icon: "star.fill",
                     value: bestScore > 0 ? "\(bestScore)" : "--",
                     label: "Best Score", color: .hrGold)
            Divider().frame(height: 28).background(Color.white.opacity(0.10))
            statCell(icon: "chart.line.uptrend.xyaxis",
                     value: avgScore > 0 ? "\(avgScore)" : "--",
                     label: "Avg Score", color: .hrGreen)
        }
        .padding(.vertical, 12)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }

    private func statCell(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.32))
                .tracking(0.3)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - BaseballTipsCard
// Auto-rotating baseball tips carousel

struct BaseballTipsCard: View {
    @State private var currentIndex = 0
    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()

    private let tips: [(icon: String, color: Color, title: String, body: String)] = [
        ("figure.baseball", .hrBlue,
         "Hip Rotation",
         "Fire your hips before your hands — 70% of swing power comes from lower-body rotation."),
        ("eye.fill", .hrGreen,
         "Eye on the Ball",
         "Track the ball from the pitcher's release all the way to the point of contact."),
        ("waveform.path", .hrOrange,
         "Bat Speed",
         "A compact, short swing through the zone generates more speed than a big looping swing."),
        ("arrow.up.right.circle.fill", .hrGold,
         "Weight Transfer",
         "Shift weight from back foot to front foot smoothly — avoid lunging forward too early."),
        ("hands.clap.fill", .hrBlue,
         "Follow Through",
         "A full follow-through past the opposite shoulder means maximum power transfer."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.hrGold)
                Text("PRO TIPS")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.white.opacity(0.42))
                    .tracking(1.2)
                Spacer()
                // Dot page indicators
                HStack(spacing: 4) {
                    ForEach(0..<tips.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentIndex ? Color.hrGold : Color.white.opacity(0.18))
                            .frame(width: i == currentIndex ? 16 : 5, height: 5)
                            .animation(.spring(duration: 0.3), value: currentIndex)
                    }
                }
            }

            // Tip content (animated transition)
            let tip = tips[currentIndex]
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tip.color.opacity(0.16))
                        .frame(width: 48, height: 48)
                    Image(systemName: tip.icon)
                        .font(.system(size: 21, weight: .medium))
                        .foregroundStyle(tip.color)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(tip.body)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.52))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
            ))
            .id(currentIndex)
        }
        .hrCard()
        .onReceive(timer) { _ in
            withAnimation(.spring(duration: 0.45)) {
                currentIndex = (currentIndex + 1) % tips.count
            }
        }
    }
}

// EnhancedMapSection removed — replaced by real MapKit FieldMapView
