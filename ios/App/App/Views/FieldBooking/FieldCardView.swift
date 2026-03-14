import SwiftUI
import MapKit

// MARK: - Field Card

struct FieldCardView: View {
    let field: BaseballField
    let appeared: Bool
    let onTap: () -> Void

    private var isHighlighted: Bool {
        field.category == .battingCage || field.category == .sportComplex
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Map snapshot header with overlay info
                ZStack(alignment: .bottomLeading) {
                    MapSnapshotView(
                        coordinate: field.coordinate,
                        height: 120,
                        span: 0.006
                    )
                    .frame(height: 120)

                    // Bottom gradient overlay for text readability
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(0.75)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: 70)
                    .frame(maxHeight: .infinity, alignment: .bottom)

                    // Field info overlay
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(field.name)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

                                if isHighlighted {
                                    Text(field.category == .battingCage ? "CAGE" : "COMPLEX")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundStyle(Color.hrGold)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.hrGold.opacity(0.25))
                                        .clipShape(Capsule())
                                }

                                if field.isIndoor {
                                    Text("INDOOR")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundStyle(Color.hrOrange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.hrOrange.opacity(0.25))
                                        .clipShape(Capsule())
                                }
                            }

                            HStack(spacing: 8) {
                                Text(field.category.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.65))

                                if field.hasReviews {
                                    HStack(spacing: 3) {
                                        StarRatingView(rating: field.rating ?? 0, size: 10)
                                        Text(field.ratingDisplay ?? "")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color.hrGold)
                                        Text("(\(field.reviewCount))")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.white.opacity(0.50))
                                    }
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }

                // Details row
                HStack(spacing: 0) {
                    infoItem(icon: "mappin", value: field.distanceDisplay, label: "away")
                    Divider()
                        .frame(height: 30)
                        .background(Color.hrDivider)
                    if field.hasReviews {
                        infoItem(icon: "star.fill", value: field.ratingDisplay ?? "-", label: "\(field.reviewCount) reviews", color: .hrGold)
                    } else {
                        infoItem(icon: field.category.icon, value: field.category.rawValue, label: "type")
                    }
                    Divider()
                        .frame(height: 30)
                        .background(Color.hrDivider)
                    if let isOpen = field.isOpenNow {
                        infoItem(
                            icon: isOpen ? "checkmark.circle.fill" : "clock",
                            value: isOpen ? "Open" : "Closed",
                            label: "now",
                            color: isOpen ? .hrGreen : .hrRed
                        )
                    } else if let phone = field.formattedPhone, !phone.isEmpty {
                        infoItem(icon: "phone.fill", value: "Call", label: "field", color: .hrGreen)
                    } else {
                        infoItem(icon: "map.fill", value: "Map", label: "view", color: .hrBlue)
                    }
                }
                .padding(.vertical, 12)
                .background(Color.hrCard.opacity(0.60))

                // Address row
                HStack(spacing: 8) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.hrBlue)
                    Text(field.address)
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.55))
                        .lineLimit(1)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.hrCard.opacity(0.40))

                // Action button
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Get Directions")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isHighlighted ? Color.hrGold.opacity(0.85) : Color.hrBlue.opacity(0.85))
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isHighlighted
                            ? Color.hrGold.opacity(0.30)
                            : Color.hrStroke,
                            lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func infoItem(icon: String, value: String, label: String, color: Color = .white) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.primary.opacity(0.50))
                .textCase(.uppercase)
                .tracking(0.4)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Star Rating View

struct StarRatingView: View {
    let rating: Double
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { index in
                starImage(for: index)
                    .font(.system(size: size))
                    .foregroundStyle(Color.hrGold)
            }
        }
    }

    private func starImage(for index: Int) -> Image {
        let threshold = Double(index) + 1
        if rating >= threshold {
            return Image(systemName: "star.fill")
        } else if rating >= threshold - 0.5 {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
}
