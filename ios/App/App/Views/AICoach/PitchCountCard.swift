import SwiftUI

// MARK: - Pitch Count Card
// Tracks daily pitch count with progress ring and quick-add buttons

struct PitchCountCard: View {
    @ObservedObject var vm: AICoachViewModel

    private var limit: Int {
        BiomechanicsService.shared.dailyPitchLimit(forAge: vm.playerAge)
    }

    private var progress: Double {
        guard limit > 0 else { return 0 }
        return min(Double(vm.todayPitchCount) / Double(limit), 1.0)
    }

    private var remaining: Int {
        max(limit - vm.todayPitchCount, 0)
    }

    private var isAtLimit: Bool {
        vm.todayPitchCount >= limit
    }

    private var ringColor: Color {
        if isAtLimit { return .hrRed }
        if progress > 0.80 { return .hrOrange }
        return .hrGreen
    }

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "number.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.hrOrange)
                Text("PITCH COUNT")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.primary.opacity(0.55))
                    .tracking(1.2)
                Spacer()
                Text("Age \(vm.playerAge) · Limit \(limit)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.primary.opacity(0.50))
            }

            HStack(spacing: 20) {
                // Progress ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.hrDivider, lineWidth: 8)
                        .frame(width: 72, height: 72)

                    // Progress arc
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            ringColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(duration: 0.5), value: progress)

                    // Count text
                    VStack(spacing: 0) {
                        Text("\(vm.todayPitchCount)")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(isAtLimit ? Color.hrRed : .primary)
                            .contentTransition(.numericText())
                        Text("/ \(limit)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.50))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    // Status text
                    if isAtLimit {
                        Label("Limit reached — rest required", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.hrRed)
                    } else {
                        Text("\(remaining) pitches remaining")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.60))
                    }

                    // Quick add buttons
                    HStack(spacing: 8) {
                        pitchButton("+1", amount: 1)
                        pitchButton("+5", amount: 5)
                        pitchButton("+10", amount: 10)

                        Spacer()

                        // Reset
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                vm.resetPitchCount()
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.primary.opacity(0.50))
                                .padding(8)
                                .background(Color.hrSurface)
                                .clipShape(Circle())
                        }
                    }

                    // Rest days info
                    if vm.todayPitchCount > 0 {
                        let rest = BiomechanicsService.shared.restDaysRequired(
                            forAge: vm.playerAge,
                            pitchCount: vm.todayPitchCount
                        )
                        Text("Required rest: \(rest) day\(rest == 1 ? "" : "s")")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.45))
                    }
                }
            }
        }
        .hrCard()
    }

    private func pitchButton(_ label: String, amount: Int) -> some View {
        Button {
            withAnimation(.spring(duration: 0.25)) {
                vm.incrementPitchCount(by: amount)
            }
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary.opacity(isAtLimit ? 0.40 : 1.0))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isAtLimit
                            ? Color.hrSurface
                            : Color.hrOrange.opacity(0.22))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isAtLimit
                                ? Color.hrSurface
                                : Color.hrOrange.opacity(0.35),
                                lineWidth: 1)
                )
        }
        .disabled(isAtLimit)
    }
}
