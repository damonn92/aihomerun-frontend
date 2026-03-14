import SwiftUI
import MapKit

struct FieldMapView: View {
    let fields: [BaseballField]
    let userLocation: CLLocationCoordinate2D?
    @Binding var region: MKCoordinateRegion
    let onFieldTap: (BaseballField) -> Void

    var body: some View {
        ZStack {
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                annotationItems: fields
            ) { field in
                MapAnnotation(coordinate: field.coordinate) {
                    FieldMapPin(field: field) {
                        onFieldTap(field)
                    }
                }
            }
            .tint(Color.hrBlue)

            // Bottom gradient fade into hrBg
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.hrBg],
                    startPoint: UnitPoint(x: 0.5, y: 0.0),
                    endPoint: .bottom
                )
                .frame(height: 50)
            }

            // Top badges
            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.hrGreen)
                            .frame(width: 6, height: 6)
                        Text("\(fields.count) Fields")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.primary.opacity(0.70))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial.opacity(0.6))
                    .clipShape(Capsule())
                    .padding(.top, 10)
                    .padding(.trailing, 14)
                }
                Spacer()
            }
        }
        .clipShape(Rectangle())
    }
}

// MARK: - Field Map Pin

struct FieldMapPin: View {
    let field: BaseballField
    let onTap: () -> Void
    @State private var pulse = false

    private var isHighlighted: Bool {
        field.category == .battingCage || field.category == .sportComplex
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isHighlighted {
                    Circle()
                        .stroke(Color.hrGold.opacity(pulse ? 0 : 0.50), lineWidth: 2)
                        .frame(width: pulse ? 36 : 20, height: pulse ? 36 : 20)
                        .animation(.easeOut(duration: 1.5).repeatForever(autoreverses: false), value: pulse)
                }

                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(isHighlighted ? Color.hrGold : Color.hrBlue)
                            .frame(width: 26, height: 26)
                            .shadow(color: (isHighlighted ? Color.hrGold : Color.hrBlue).opacity(0.6), radius: 5)
                        Image(systemName: field.category.icon)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    // Pin tail
                    FieldPinTail()
                        .fill(isHighlighted ? Color.hrGold : Color.hrBlue)
                        .frame(width: 8, height: 6)
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear { pulse = true }
    }
}

// MARK: - Pin Tail Shape

struct FieldPinTail: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: .init(x: rect.midX, y: rect.maxY))
            p.addLine(to: .init(x: rect.minX, y: rect.minY))
            p.addLine(to: .init(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}
