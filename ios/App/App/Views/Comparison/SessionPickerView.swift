import SwiftUI

// MARK: - Session Picker View

struct SessionPickerView: View {
    let sessions: [ComparisonSession]
    let onSelect: (ComparisonSession) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                if sessions.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            ForEach(sessions) { session in
                                sessionRow(session)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Select Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.hrBlue)
                    }
                }
            }
        }
    }

    // MARK: - Session Row

    private func sessionRow(_ session: ComparisonSession) -> some View {
        Button {
            onSelect(session)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                // Date column
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.displayLabel)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    if let type = session.sessionSummary.actionType {
                        Text(type.capitalized)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.55))
                    }
                }

                Spacer()

                // Score
                if let score = session.overallScore {
                    VStack(spacing: 1) {
                        Text("\(score)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(scoreColor(score))

                        Text("Score")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.primary.opacity(0.45))
                    }
                }

                // Video availability badge
                if session.videoAvailable {
                    Image(systemName: "film")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.hrGreen)
                        .frame(width: 24)
                } else {
                    Image(systemName: "film.slash")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.hrOrange)
                        .frame(width: 24)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.35))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.hrSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.hrStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 40))
                .foregroundStyle(.primary.opacity(0.35))

            Text("No Previous Sessions")
                .font(.headline)
                .foregroundStyle(.primary.opacity(0.60))

            Text("Record and analyze more swings to compare them.")
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.45))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Helpers

    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return Color.hrGreen
        case 60..<80:  return Color.hrBlue
        case 40..<60:  return Color.hrOrange
        default:       return Color.hrRed
        }
    }
}
