import Foundation
import CoreLocation
import MapKit

// MARK: - Baseball Field Model

struct BaseballField: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let distance: CLLocationDistance?
    let phoneNumber: String?
    let url: URL?
    let category: FieldCategory
    let mapItem: MKMapItem

    // Google Reviews data (enriched after initial search)
    var rating: Double?
    var reviewCount: Int = 0
    var reviews: [GoogleReview] = []
    var isOpenNow: Bool?
    var isIndoor: Bool = false

    var distanceMiles: Double {
        guard let distance else { return 0 }
        return distance / 1609.34
    }

    var distanceDisplay: String {
        let miles = distanceMiles
        if miles < 0.1 {
            return "Nearby"
        } else if miles < 10 {
            return String(format: "%.1f mi", miles)
        } else {
            return String(format: "%.0f mi", miles)
        }
    }

    var formattedPhone: String? {
        phoneNumber
    }

    var ratingDisplay: String? {
        guard let rating else { return nil }
        return String(format: "%.1f", rating)
    }

    var hasReviews: Bool {
        rating != nil && reviewCount > 0
    }

    static func == (lhs: BaseballField, rhs: BaseballField) -> Bool {
        lhs.id == rhs.id
    }

    /// Enrich field with Google Places review data
    func withReviewData(_ data: PlaceReviewData) -> BaseballField {
        var field = self
        field.rating = data.rating
        field.reviewCount = data.reviewCount
        field.reviews = data.reviews
        field.isOpenNow = data.isOpenNow
        field.isIndoor = data.isIndoor || self.isIndoor
        return field
    }

    /// Build a BaseballField from an MKMapItem
    static func from(mapItem: MKMapItem, userLocation: CLLocationCoordinate2D?) -> BaseballField {
        let placemark = mapItem.placemark
        let coord = placemark.coordinate

        let dist: CLLocationDistance? = {
            guard let userLoc = userLocation else { return nil }
            return CLLocation(latitude: userLoc.latitude, longitude: userLoc.longitude)
                .distance(from: CLLocation(latitude: coord.latitude, longitude: coord.longitude))
        }()

        let addr = formatAddress(placemark)
        let cat = categorizeField(mapItem)

        return BaseballField(
            id: "\(coord.latitude),\(coord.longitude)-\(mapItem.name ?? "")",
            name: mapItem.name ?? "Baseball Field",
            address: addr,
            coordinate: coord,
            distance: dist,
            phoneNumber: mapItem.phoneNumber,
            url: mapItem.url,
            category: cat,
            mapItem: mapItem,
            isIndoor: detectIndoor(mapItem)
        )
    }

    private static func formatAddress(_ placemark: CLPlacemark) -> String {
        var parts: [String] = []
        if let street = placemark.thoroughfare {
            if let number = placemark.subThoroughfare {
                parts.append("\(number) \(street)")
            } else {
                parts.append(street)
            }
        }
        if let city = placemark.locality {
            parts.append(city)
        }
        if let state = placemark.administrativeArea {
            parts.append(state)
        }
        return parts.isEmpty ? "Address unavailable" : parts.joined(separator: ", ")
    }

    private static func categorizeField(_ mapItem: MKMapItem) -> FieldCategory {
        let name = (mapItem.name ?? "").lowercased()

        if name.contains("batting cage") || name.contains("batting center") {
            return .battingCage
        } else if name.contains("softball") {
            return .softballField
        } else if name.contains("baseball") || name.contains("diamond") || name.contains("little league") {
            return .baseballField
        } else if name.contains("complex") || name.contains("center") || name.contains("facility") || name.contains("stadium") {
            return .sportComplex
        } else if name.contains("park") || name.contains("recreation") {
            return .park
        }

        return .baseballField
    }

    private static func detectIndoor(_ mapItem: MKMapItem) -> Bool {
        let name = (mapItem.name ?? "").lowercased()
        let indoorKeywords = ["indoor", "inside", "dome", "covered", "training center",
                              "academy", "facility", "center", "gym", "warehouse"]
        return indoorKeywords.contains { name.contains($0) }
    }
}

// MARK: - Field Category

enum FieldCategory: String, CaseIterable {
    case baseballField = "Baseball Field"
    case softballField = "Softball Field"
    case battingCage = "Batting Cage"
    case sportComplex = "Sports Complex"
    case park = "Park"

    var icon: String {
        switch self {
        case .baseballField: return "diamond.fill"
        case .softballField: return "diamond.fill"
        case .battingCage:   return "figure.baseball"
        case .sportComplex:  return "building.2.fill"
        case .park:          return "leaf.fill"
        }
    }
}

// MARK: - Field Filter

enum FieldFilter: String, CaseIterable {
    case all = "All"
    case nearest = "Nearest"
    case baseball = "Baseball"
    case softball = "Softball"
    case cages = "Cages"
    case indoor = "Indoor"
    case withinMile = "< 1 mi"

    var icon: String {
        switch self {
        case .all:        return "square.grid.2x2"
        case .nearest:    return "location.fill"
        case .baseball:   return "diamond.fill"
        case .softball:   return "diamond"
        case .cages:      return "figure.baseball"
        case .indoor:     return "building.fill"
        case .withinMile: return "mappin.circle"
        }
    }
}

// MARK: - Search State

enum FieldSearchState: Equatable {
    case idle
    case searching
    case results
    case noResults
    case error(String)

    static func == (lhs: FieldSearchState, rhs: FieldSearchState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.searching, .searching),
             (.results, .results), (.noResults, .noResults):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Default Region

extension MKCoordinateRegion {
    static let sanFranciscoDefault = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
}
