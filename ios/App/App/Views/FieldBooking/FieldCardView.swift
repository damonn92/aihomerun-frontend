import SwiftUI

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
                // Card header with gradient
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: isHighlighted
                        ? [Color.hrGold.opacity(0.30), Color.hrCard]
                        : [Color.hrBlue.opacity(0.18), Color.hrCard],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(height: 80)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(field.name)
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)

                                if isHighlighted {
                                    Text(field.category == .battingCage ? "CAGE" : "COMPLEX")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundStyle(Color.hrGold)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.hrGold.opacity(0.15))
                                        .clipShape(Capsule())
                                }

                                if field.isIndoor {
                                    Text("INDOOR")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundStyle(Color.hrOrange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.hrOrange.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }

                            HStack(spacing: 8) {
                                Text(field.category.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.45))

                                if field.hasReviews {
                                    HStack(spacing: 3) {
                                        StarRatingView(rating: field.rating ?? 0, size: 10)
                                        Text(field.ratingDisplay ?? "")
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color.hrGold)
                                        Text("(\(field.reviewCount))")
                                            .font(.system(size: 10))
                                            .foregroundStyle(.white.opacity(0.35))
                                    }
                                }
                            }
                        }
                        Spacer()
                        Image(systemName: field.category.icon)
                            .font(.system(size: 28, weight: .light))
                            .foregroundStyle(.white.opacity(0.10))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }

                // Details row
                HStack(spacing: 0) {
                    infoItem(icon: "mappin", value: field.distanceDisplay, label: "away")
                    Divider()
                        .frame(height: 30)
                        .background(Color.white.opacity(0.08))
                    if field.hasReviews {
                        infoItem(icon: "star.fill", value: field.ratingDisplay ?? "-", label: "\(field.reviewCount) reviews", color: .hrGold)
                    } else {
                        infoItem(icon: field.category.icon, value: field.category.rawValue, label: "type")
                    }
                    Divider()
                        .frame(height: 30)
                        .background(Color.white.opacity(0.08))
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
                        .foregroundStyle(.white.opacity(0.55))
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
                            : Color.white.opacity(0.09),
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
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
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
