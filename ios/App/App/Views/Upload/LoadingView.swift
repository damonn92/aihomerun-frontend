import SwiftUI

struct LoadingView: View {
    let step: Int
    let progress: Double

    private let steps: [(icon: String, label: String, sub: String)] = [
        ("arrow.up.circle.fill",    "Uploading Video",      "Sending to AI server…"),
        ("figure.walk.circle.fill", "Analyzing Pose",       "Detecting body landmarks…"),
        ("wand.and.stars",          "Generating Feedback",  "Building your report…"),
        ("checkmark.circle.fill",   "Almost Done",          "Finalizing results…"),
    ]

    @State private var pulsing = false
    @State private var spin: Double = 0

    private var current: (icon: String, label: String, sub: String) {
        steps[min(step, steps.count - 1)]
    }

    var body: some View {
        ZStack {
            Color.hrBg.ignoresSafeArea()

            RadialGradient(
                colors: [Color.hrBlue.opacity(0.22), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 220
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Icon ─────────────────────────────────────────────────
                ZStack {
                    Circle()
                        .fill(Color.hrBlue.opacity(0.12))
                        .frame(width: 140, height: 140)
                        .blur(radius: pulsing ? 32 : 16)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulsing)

                    Circle()
                        .trim(from: 0, to: 0.65)
                        .stroke(
                            Color.hrBlue.opacity(0.5),
                            style: StrokeStyle(lineWidth: 2, dash: [5, 8])
                        )
                        .frame(width: 108, height: 108)
                        .rotationEffect(.degrees(spin))
                        .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: spin)

                    Circle()
                        .fill(Color.hrBlue.opacity(0.16))
                        .frame(width: 86, height: 86)

                    Image(systemName: current.icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(Color.hrBlue)
                        .scaleEffect(pulsing ? 1.10 : 0.93)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulsing)
                }
                .padding(.bottom, 30)

                // ── Labels ───────────────────────────────────────────────
                VStack(spacing: 6) {
                    Text(current.label)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .id("lbl-\(step)")
                        .transition(.opacity)
                    Text(current.sub)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.42))
                        .id("sub-\(step)")
                        .transition(.opacity)
                }
                .padding(.bottom, 36)
                .animation(.easeInOut(duration: 0.3), value: step)

                // ── Checklist ────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { idx, s in
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        idx < step  ? Color.hrGreen.opacity(0.18) :
                                        idx == step ? Color.hrBlue.opacity(0.18) :
                                                      Color.white.opacity(0.06)
                                    )
                                    .frame(width: 32, height: 32)

                                if idx < step {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(Color.hrGreen)
                                } else if idx == step {
                                    Circle()
                                        .trim(from: 0, to: 0.7)
                                        .stroke(Color.hrBlue,
                                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                        .frame(width: 16, height: 16)
                                        .rotationEffect(.degrees(spin * 2.5))
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.14))
                                        .frame(width: 8, height: 8)
                                }
                            }

                            Text(s.label)
                                .font(.subheadline.weight(idx <= step ? .semibold : .regular))
                                .foregroundStyle(
                                    idx < step  ? Color.hrGreen :
                                    idx == step ? .white :
                                                  .white.opacity(0.26)
                                )
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 44)
                .padding(.bottom, 32)

                // ── Progress bar ─────────────────────────────────────────
                VStack(spacing: 10) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.hrBlue, Color(red: 0.38, green: 0.70, blue: 1.0)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * max(progress, 0.04), height: 6)
                                .animation(.linear(duration: 0.35), value: progress)
                        }
                    }
                    .frame(height: 6)

                    Text("This takes 30–60 seconds")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.28))
                }
                .padding(.horizontal, 44)

                Spacer()
            }
        }
        .onAppear {
            pulsing = true
            spin = 360
        }
    }
}
