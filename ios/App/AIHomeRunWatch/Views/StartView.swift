import SwiftUI

/// Starting screen — configure and begin a practice session
struct StartView: View {
    @EnvironmentObject var viewModel: SessionViewModel
    @State private var showPlayerPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // App header with real logo
                HStack(spacing: 6) {
                    Image("AppLogo")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text("AIHomeRun")
                        .font(.system(size: 15, weight: .bold))
                }
                .padding(.bottom, 4)

                // Batting hand selector
                VStack(alignment: .leading, spacing: 4) {
                    Text("Batting Hand")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(BattingHand.allCases, id: \.self) { hand in
                            Button {
                                viewModel.battingHand = hand
                            } label: {
                                Text(hand.abbreviation)
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(
                                        viewModel.battingHand == hand ?
                                        Color.green.opacity(0.3) : Color.gray.opacity(0.2)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                viewModel.battingHand == hand ?
                                                Color.green : Color.clear,
                                                lineWidth: 1.5
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Player selector (tappable)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Player")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    Button {
                        showPlayerPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.green)
                            Text(viewModel.playerName)
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("Age \(viewModel.playerAge)")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }

                // Practice Mode selector
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mode")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        ForEach(PracticeMode.allCases, id: \.self) { mode in
                            Button {
                                viewModel.practiceMode = mode
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 11))
                                    Text(mode.rawValue)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    viewModel.practiceMode == mode ?
                                    Color.blue.opacity(0.3) : Color.gray.opacity(0.2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(
                                            viewModel.practiceMode == mode ?
                                            Color.blue : Color.clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if viewModel.practiceMode == .airSwing {
                        Text("No ball needed — detects swing motion only")
                            .font(.system(size: 9))
                            .foregroundStyle(.blue.opacity(0.8))
                            .padding(.horizontal, 2)
                    }
                }

                // Sensor info
                HStack {
                    Image(systemName: viewModel.motionService.sensorRate == .highFrequency ?
                          "waveform.path" : "waveform")
                        .font(.system(size: 12))
                        .foregroundStyle(viewModel.motionService.sensorRate == .highFrequency ? .green : .orange)

                    Text(viewModel.motionService.sensorRate == .highFrequency ?
                         "800Hz High-Freq" : "100Hz Standard")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.horizontal, 4)

                // Start button
                Button {
                    Task {
                        await viewModel.startSession()
                    }
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Practice")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Recent sessions
                if !viewModel.recentSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recent")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)

                        ForEach(viewModel.recentSessions.prefix(3)) { session in
                            RecentSessionRow(session: session)
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .sheet(isPresented: $showPlayerPicker) {
            PlayerPickerView()
                .environmentObject(viewModel)
        }
    }
}

// MARK: - Player Picker View

struct PlayerPickerView: View {
    @EnvironmentObject var viewModel: SessionViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Select Player")
                    .font(.system(size: 15, weight: .bold))
                    .padding(.top, 4)

                // Synced players from iPhone
                if !viewModel.syncedPlayers.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("From iPhone")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)

                        ForEach(viewModel.syncedPlayers) { player in
                            Button {
                                viewModel.selectPlayer(player)
                                dismiss()
                            } label: {
                                PlayerRow(
                                    name: player.name,
                                    age: player.age,
                                    isSelected: viewModel.playerName == player.name
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    // No synced players — show instructions
                    VStack(spacing: 6) {
                        Image(systemName: "iphone.and.arrow.forward")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                        Text("Add players in the\niPhone app to sync")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 8)
                }

                Divider()

                // Quick age adjuster (for when no iPhone sync)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Setup")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)

                    // Name
                    HStack {
                        Text("Name")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(viewModel.playerName)
                            .font(.system(size: 12, weight: .medium))
                    }

                    // Age stepper
                    HStack {
                        Text("Age")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            if viewModel.playerAge > 4 {
                                viewModel.playerAge -= 1
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)

                        Text("\(viewModel.playerAge)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .frame(width: 30)

                        Button {
                            if viewModel.playerAge < 25 {
                                viewModel.playerAge += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.green)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Player Row

struct PlayerRow: View {
    let name: String
    let age: Int
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundStyle(isSelected ? .green : .secondary)
            Text(name)
                .font(.system(size: 13))
            Spacer()
            Text("Age \(age)")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(isSelected ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Recent Session Row

struct RecentSessionRow: View {
    let session: SessionSummaryWatch

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.date, style: .date)
                    .font(.system(size: 11))
                Text("\(session.swingCount) swings")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(session.maxHandSpeed))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.green)
                Text("mph best")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    StartView()
        .environmentObject(SessionViewModel())
}
