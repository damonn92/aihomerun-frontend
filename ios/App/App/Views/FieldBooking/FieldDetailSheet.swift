import SwiftUI
import MapKit

struct FieldDetailSheet: View {
    let field: BaseballField
    @Environment(\.dismiss) var dismiss

    private var isHighlighted: Bool {
        field.category == .battingCage || field.category == .sportComplex
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // Hero section
                        ZStack {
                            LinearGradient(
                                colors: isHighlighted
                                ? [Color.hrGold.opacity(0.28), Color.hrCard]
                                : [Color.hrBlue.opacity(0.25), Color.hrCard],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                            VStack(spacing: 8) {
                                Image(systemName: field.category.icon)
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundStyle(.white.opacity(0.15))
                                Text(field.name)
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                                    .multilineTextAlignment(.center)
                                Text(field.address)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.45))
                                    .multilineTextAlignment(.center)

                                // Badges row
                                HStack(spacing: 8) {
                                    if field.isIndoor {
                                        badgePill(text: "INDOOR", color: .hrOrange)
                                    }
                                    if let isOpen = field.isOpenNow {
                                        badgePill(
                                            text: isOpen ? "OPEN NOW" : "CLOSED",
                                            color: isOpen ? .hrGreen : .hrRed
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.horizontal, 20)

                        // Rating summary (if reviews available)
                        if field.hasReviews {
                            ratingSummaryCard
                                .padding(.horizontal, 20)
                        }

                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            detailStat(
                                icon: "mappin.circle.fill",
                                label: "Distance",
                                value: field.distanceDisplay,
                                color: .hrBlue
                            )
                            detailStat(
                                icon: field.category.icon,
                                label: "Category",
                                value: field.category.rawValue,
                                color: isHighlighted ? .hrGold : .hrGreen
                            )
                            if let phone = field.formattedPhone, !phone.isEmpty {
                                detailStat(
                                    icon: "phone.fill",
                                    label: "Phone",
                                    value: phone,
                                    color: .hrGreen
                                )
                            }
                            if let url = field.url {
                                detailStat(
                                    icon: "globe",
                                    label: "Website",
                                    value: url.host ?? "Visit",
                                    color: .hrOrange
                                )
                            }
                        }
                        .padding(.horizontal, 20)

                        // Google Reviews section
                        if !field.reviews.isEmpty {
                            reviewsSection
                                .padding(.horizontal, 20)
                        }

                        // Mini map
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Location", systemImage: "map.fill")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(Color.hrBlue)
                                .textCase(.uppercase)
                                .tracking(0.5)

                            Map(coordinateRegion: .constant(
                                MKCoordinateRegion(
                                    center: field.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            ), annotationItems: [field]) { f in
                                MapAnnotation(coordinate: f.coordinate) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.hrBlue)
                                            .frame(width: 20, height: 20)
                                            .shadow(color: Color.hrBlue.opacity(0.6), radius: 5)
                                        Image(systemName: "diamond.fill")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .allowsHitTesting(false)
                        }
                        .hrCard()
                        .padding(.horizontal, 20)

                        // Action buttons
                        VStack(spacing: 12) {
                            // Get Directions (primary)
                            Button {
                                field.mapItem.openInMaps(launchOptions: [
                                    MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
                                ])
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Get Directions")
                                        .font(.headline)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(
                                    LinearGradient(
                                        colors: [Color.hrBlue, Color(red: 0.04, green: 0.36, blue: 0.80)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.hrBlue.opacity(0.50), radius: 12, y: 4)
                            }

                            // Secondary actions
                            HStack(spacing: 12) {
                                // Call button
                                if let phone = field.phoneNumber, !phone.isEmpty {
                                    Button {
                                        if let url = URL(string: "tel://\(phone.replacingOccurrences(of: " ", with: ""))") {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "phone.fill")
                                                .font(.system(size: 14, weight: .semibold))
                                            Text("Call")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(Color.hrGreen.opacity(0.85))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    }
                                }

                                // Website button
                                if let url = field.url {
                                    Button {
                                        UIApplication.shared.open(url)
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "globe")
                                                .font(.system(size: 14, weight: .semibold))
                                            Text("Website")
                                                .font(.subheadline.weight(.semibold))
                                        }
                                        .foregroundStyle(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 48)
                                        .background(Color.white.opacity(0.10))
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                        )
                                    }
                                }

                                // Open in Maps
                                Button {
                                    field.mapItem.openInMaps()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "map.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                        Text("Maps")
                                            .font(.subheadline.weight(.semibold))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color.white.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle(field.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
    }

    // MARK: - Rating Summary Card

    private var ratingSummaryCard: some View {
        HStack(spacing: 16) {
            // Big rating number
            VStack(spacing: 4) {
                Text(field.ratingDisplay ?? "-")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                StarRatingView(rating: field.rating ?? 0, size: 14)
                Text("\(field.reviewCount) reviews")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(width: 100)

            // Rating bars
            VStack(spacing: 4) {
                ForEach((1...5).reversed(), id: \.self) { star in
                    let count = field.reviews.filter { $0.rating == star }.count
                    let fraction = field.reviews.isEmpty ? 0 : Double(count) / Double(field.reviews.count)
                    HStack(spacing: 6) {
                        Text("\(star)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: 12)
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.hrGold)
                                    .frame(width: geo.size.width * fraction, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
        }
        .hrCard()
    }

    // MARK: - Reviews Section

    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Google Reviews", systemImage: "star.bubble.fill")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.hrGold)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                Text("\(field.reviews.count) of \(field.reviewCount)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }

            ForEach(field.reviews) { review in
                reviewCard(review)
            }
        }
        .hrCard()
    }

    private func reviewCard(_ review: GoogleReview) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                // Author avatar placeholder
                Circle()
                    .fill(Color.hrBlue.opacity(0.3))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(review.authorName.prefix(1)).uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.hrBlue)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(review.authorName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        StarRatingView(rating: Double(review.rating), size: 10)
                        Text(review.relativeTime)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                Spacer()
            }

            if !review.text.isEmpty {
                Text(review.text)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(4)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Badge Pill

    private func badgePill(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .black))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    // MARK: - Stat Cell

    private func detailStat(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}
