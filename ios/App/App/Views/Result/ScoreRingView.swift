import SwiftUI

struct ScoreRingView: View {
    let score: Int
    let label: String
    var size: CGFloat = 72
    var lineWidth: CGFloat = 7

    @State private var animatedScore: Int = 0

    private var fraction: Double { Double(animatedScore) / 100.0 }

    private var ringColor: Color {
        switch score {
        case 80...100: return Color.hrGreen
        case 60..<80:  return Color.hrBlue
        case 40..<60:  return Color.hrOrange
        default:       return Color.hrRed
        }
    }

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                // Track ring
                Circle()
                    .stroke(ringColor.opacity(0.14), lineWidth: lineWidth)

                // Progress ring
                Circle()
                    .trim(from: 0, to: fraction)
                    .stroke(
                        AngularGradient(
                            colors: [ringColor.opacity(0.6), ringColor],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-90 + 360 * fraction)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 1.1, bounce: 0.3), value: animatedScore)

                // Glow dot at tip
                Circle()
                    .fill(ringColor)
                    .frame(width: lineWidth, height: lineWidth)
                    .offset(y: -(size / 2))
                    .rotationEffect(.degrees(-90 + 360 * fraction))
                    .animation(.spring(duration: 1.1, bounce: 0.3), value: animatedScore)
                    .shadow(color: ringColor.opacity(0.8), radius: 4)
                    .opacity(fraction > 0.02 ? 1 : 0)

                // Score number
                Text("\(animatedScore)")
                    .font(.system(size: size * 0.30, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 1.1), value: animatedScore)
            }
            .frame(width: size, height: size)

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.55))
                .textCase(.uppercase)
                .tracking(0.5)
                .lineLimit(1)
        }
        .onAppear {
            withAnimation(.spring(duration: 1.1, bounce: 0.3).delay(0.25)) {
                animatedScore = score
            }
        }
    }
}
