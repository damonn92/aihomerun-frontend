import Foundation
import CoreLocation

// MARK: - Google Places Service

/// Fetches place details and reviews from Google Places API (New)
actor GooglePlacesService {
    static let shared = GooglePlacesService()

    private let session = URLSession.shared
    private let baseURL = "https://places.googleapis.com/v1"
    private var cache: [String: PlaceReviewData] = [:]

    private var apiKey: String { AppConfig.googlePlacesAPIKey }

    // MARK: - Public API

    /// Search for a place by name + location, return review data
    func fetchReviews(name: String, coordinate: CLLocationCoordinate2D) async -> PlaceReviewData? {
        let cacheKey = "\(coordinate.latitude),\(coordinate.longitude)-\(name)"
        if let cached = cache[cacheKey] { return cached }

        guard !apiKey.isEmpty, apiKey != "YOUR_GOOGLE_PLACES_API_KEY" else { return nil }

        // Step 1: Search for the place using Text Search (New)
        guard let placeId = await searchPlaceId(name: name, coordinate: coordinate) else { return nil }

        // Step 2: Get place details including reviews
        guard let details = await fetchPlaceDetails(placeId: placeId) else { return nil }

        cache[cacheKey] = details
        return details
    }

    /// Batch fetch reviews for multiple fields
    func fetchReviewsBatch(fields: [(name: String, coordinate: CLLocationCoordinate2D)]) async -> [String: PlaceReviewData] {
        var results: [String: PlaceReviewData] = [:]

        await withTaskGroup(of: (String, PlaceReviewData?).self) { group in
            for field in fields {
                let key = "\(field.coordinate.latitude),\(field.coordinate.longitude)-\(field.name)"
                group.addTask {
                    let data = await self.fetchReviews(name: field.name, coordinate: field.coordinate)
                    return (key, data)
                }
            }

            for await (key, data) in group {
                if let data {
                    results[key] = data
                }
            }
        }

        return results
    }

    // MARK: - Private: Text Search

    private func searchPlaceId(name: String, coordinate: CLLocationCoordinate2D) async -> String? {
        let url = URL(string: "\(baseURL)/places:searchText")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("places.id,places.displayName,places.rating,places.userRatingCount",
                         forHTTPHeaderField: "X-Goog-FieldMask")

        let body: [String: Any] = [
            "textQuery": name,
            "locationBias": [
                "circle": [
                    "center": [
                        "latitude": coordinate.latitude,
                        "longitude": coordinate.longitude
                    ],
                    "radius": 500.0
                ]
            ],
            "maxResultCount": 1
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = jsonData

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }

            let result = try JSONDecoder().decode(TextSearchResponse.self, from: data)
            return result.places?.first?.id
        } catch {
            return nil
        }
    }

    // MARK: - Private: Place Details

    private func fetchPlaceDetails(placeId: String) async -> PlaceReviewData? {
        let fieldMask = "id,rating,userRatingCount,reviews,currentOpeningHours,types"
        let urlString = "\(baseURL)/places/\(placeId)?languageCode=en"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(fieldMask, forHTTPHeaderField: "X-Goog-FieldMask")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return nil }

            let detail = try JSONDecoder().decode(PlaceDetailResponse.self, from: data)

            let reviews: [GoogleReview] = (detail.reviews ?? []).prefix(5).map { review in
                GoogleReview(
                    authorName: review.authorAttribution?.displayName ?? "Anonymous",
                    authorPhotoURL: review.authorAttribution?.photoUri,
                    rating: review.rating ?? 0,
                    text: review.text?.text ?? "",
                    relativeTime: review.relativePublishTimeDescription ?? "",
                    publishTime: review.publishTime
                )
            }

            let isIndoor = checkIfIndoor(types: detail.types)

            return PlaceReviewData(
                placeId: placeId,
                rating: detail.rating,
                reviewCount: detail.userRatingCount ?? 0,
                reviews: reviews,
                isOpenNow: detail.currentOpeningHours?.openNow,
                isIndoor: isIndoor
            )
        } catch {
            return nil
        }
    }

    private func checkIfIndoor(types: [String]?) -> Bool {
        guard let types else { return false }
        let indoorIndicators: Set<String> = [
            "gym", "sports_complex", "fitness_center",
            "health", "bowling_alley", "amusement_center"
        ]
        return types.contains { indoorIndicators.contains($0) }
    }
}

// MARK: - Google API Response Models

private struct TextSearchResponse: Decodable {
    let places: [TextSearchPlace]?
}

private struct TextSearchPlace: Decodable {
    let id: String?
    let displayName: DisplayName?
    let rating: Double?
    let userRatingCount: Int?
}

private struct DisplayName: Decodable {
    let text: String?
    let languageCode: String?
}

private struct PlaceDetailResponse: Decodable {
    let id: String?
    let rating: Double?
    let userRatingCount: Int?
    let reviews: [GooglePlaceReview]?
    let currentOpeningHours: OpeningHours?
    let types: [String]?
}

private struct GooglePlaceReview: Decodable {
    let authorAttribution: AuthorAttribution?
    let rating: Int?
    let text: LocalizedText?
    let relativePublishTimeDescription: String?
    let publishTime: String?
}

private struct AuthorAttribution: Decodable {
    let displayName: String?
    let photoUri: String?
}

private struct LocalizedText: Decodable {
    let text: String?
    let languageCode: String?
}

private struct OpeningHours: Decodable {
    let openNow: Bool?
}

// MARK: - Public Review Models

struct PlaceReviewData {
    let placeId: String
    let rating: Double?
    let reviewCount: Int
    let reviews: [GoogleReview]
    let isOpenNow: Bool?
    let isIndoor: Bool
}

struct GoogleReview: Identifiable {
    let id = UUID()
    let authorName: String
    let authorPhotoURL: String?
    let rating: Int
    let text: String
    let relativeTime: String
    let publishTime: String?

    var starsDisplay: String {
        String(repeating: "\u{2605}", count: rating) + String(repeating: "\u{2606}", count: max(0, 5 - rating))
    }
}
