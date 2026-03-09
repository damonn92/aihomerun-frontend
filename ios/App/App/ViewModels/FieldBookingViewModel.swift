import Foundation
import MapKit
import CoreLocation
import Combine

@MainActor
class FieldBookingViewModel: NSObject, ObservableObject {

    // MARK: - Published State

    @Published var fields: [BaseballField] = []
    @Published var selectedFilter: FieldFilter = .all
    @Published var selectedField: BaseballField?
    @Published var searchState: FieldSearchState = .idle
    @Published var searchText: String = ""
    @Published var searchCompletions: [MKLocalSearchCompletion] = []
    @Published var mapRegion: MKCoordinateRegion = .sanFranciscoDefault
    @Published var showLocationPermissionPrompt = false

    /// The reference point for distance calculations — either search center or user GPS
    private var distanceReferencePoint: CLLocationCoordinate2D?

    // MARK: - Dependencies

    let locationManager = LocationManager.shared
    private var cancellables = Set<AnyCancellable>()
    private let searchCompleter = MKLocalSearchCompleter()
    private var currentSearchTask: Task<Void, Never>?

    // MARK: - Computed

    var locationName: String { locationManager.locationName }

    var userCoordinate: CLLocationCoordinate2D? { locationManager.userLocation }

    var filteredFields: [BaseballField] {
        let sorted = fields.sorted { ($0.distance ?? .infinity) < ($1.distance ?? .infinity) }
        switch selectedFilter {
        case .all:
            return sorted
        case .nearest:
            return Array(sorted.prefix(10))
        case .baseball:
            return sorted.filter { $0.category == .baseballField }
        case .softball:
            return sorted.filter { $0.category == .softballField }
        case .cages:
            return sorted.filter { $0.category == .battingCage }
        case .indoor:
            return sorted.filter { $0.isIndoor }
        case .withinMile:
            return sorted.filter { ($0.distanceMiles) < 1.0 }
        }
    }

    var isSearching: Bool { searchState == .searching }

    // MARK: - Init

    override init() {
        super.init()
        setupSearchCompleter()
        observeLocation()
    }

    // MARK: - Lifecycle

    func load() {
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            showLocationPermissionPrompt = true
        } else if locationManager.hasPermission {
            locationManager.startUpdating()
        } else {
            // Denied — show default region, allow manual search
            searchNearby(coordinate: mapRegion.center)
        }
    }

    func requestLocationPermission() {
        showLocationPermissionPrompt = false
        locationManager.requestPermission()
    }

    // MARK: - Search

    func searchNearby(coordinate: CLLocationCoordinate2D) {
        currentSearchTask?.cancel()
        currentSearchTask = Task {
            await performFieldSearch(center: coordinate)
        }
    }

    func searchAddress(_ query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        currentSearchTask?.cancel()
        currentSearchTask = Task {
            searchState = .searching

            // First geocode the address to get coordinates
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.resultTypes = .address

            do {
                let search = MKLocalSearch(request: request)
                let response = try await search.start()
                guard let firstItem = response.mapItems.first else {
                    searchState = .noResults
                    return
                }

                let center = firstItem.placemark.coordinate
                mapRegion = MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                )

                // Now search for fields near that location
                await performFieldSearch(center: center)
            } catch {
                if !Task.isCancelled {
                    searchState = .error("Search failed. Please try again.")
                }
            }
        }
    }

    func selectCompletion(_ completion: MKLocalSearchCompletion) {
        searchText = completion.title
        searchCompletions = []
        searchAddress(completion.title + " " + completion.subtitle)
    }

    func clearSearch() {
        searchText = ""
        searchCompletions = []
        if let coord = userCoordinate {
            searchNearby(coordinate: coord)
            mapRegion = MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        }
    }

    // MARK: - Private Search

    private func performFieldSearch(center: CLLocationCoordinate2D) async {
        searchState = .searching
        distanceReferencePoint = center

        let queries = ["baseball field", "softball field", "batting cage",
                       "indoor batting cage", "indoor baseball training"]
        let region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: 16000,
            longitudinalMeters: 16000
        )

        var allFields: [BaseballField] = []
        // Use the search center as the reference for distance, NOT the user's GPS
        let refPoint = center

        await withTaskGroup(of: [BaseballField].self) { group in
            for query in queries {
                group.addTask {
                    let request = MKLocalSearch.Request()
                    request.naturalLanguageQuery = query
                    request.region = region
                    request.resultTypes = .pointOfInterest

                    do {
                        let search = MKLocalSearch(request: request)
                        let response = try await search.start()
                        return response.mapItems.map { item in
                            BaseballField.from(mapItem: item, userLocation: refPoint)
                        }
                    } catch {
                        return []
                    }
                }
            }

            for await result in group {
                allFields.append(contentsOf: result)
            }
        }

        if Task.isCancelled { return }

        // Deduplicate by proximity (within 50 meters = same place)
        let deduplicated = deduplicateByProximity(allFields, threshold: 50)

        fields = deduplicated
        searchState = deduplicated.isEmpty ? .noResults : .results

        // Update map region to show all results
        if !deduplicated.isEmpty {
            mapRegion = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
            )
        }

        // Enrich fields with Google Reviews in background
        if !deduplicated.isEmpty {
            await enrichFieldsWithReviews(deduplicated)
        }
    }

    // MARK: - Google Reviews Enrichment

    private func enrichFieldsWithReviews(_ fieldList: [BaseballField]) async {
        let batchInput = fieldList.map { (name: $0.name, coordinate: $0.coordinate) }
        let reviewsMap = await GooglePlacesService.shared.fetchReviewsBatch(fields: batchInput)

        if Task.isCancelled { return }

        // Update fields with review data
        var updatedFields = self.fields
        for (index, field) in updatedFields.enumerated() {
            let key = "\(field.coordinate.latitude),\(field.coordinate.longitude)-\(field.name)"
            if let reviewData = reviewsMap[key] {
                updatedFields[index] = field.withReviewData(reviewData)
            }
        }
        self.fields = updatedFields
    }

    private func deduplicateByProximity(_ fields: [BaseballField], threshold: CLLocationDistance) -> [BaseballField] {
        var unique: [BaseballField] = []
        for field in fields {
            let loc = CLLocation(latitude: field.coordinate.latitude, longitude: field.coordinate.longitude)
            let isDuplicate = unique.contains { existing in
                let existingLoc = CLLocation(latitude: existing.coordinate.latitude, longitude: existing.coordinate.longitude)
                return loc.distance(from: existingLoc) < threshold
            }
            if !isDuplicate {
                unique.append(field)
            }
        }
        return unique
    }

    // MARK: - Search Completer

    private func setupSearchCompleter() {
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.pointOfInterest, .address]

        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] text in
                guard let self else { return }
                if text.trimmingCharacters(in: .whitespaces).isEmpty {
                    self.searchCompletions = []
                } else {
                    self.searchCompleter.queryFragment = text
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Location Observation

    private func observeLocation() {
        locationManager.$userLocation
            .compactMap { $0 }
            .first()
            .sink { [weak self] coordinate in
                guard let self else { return }
                self.mapRegion = MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
                )
                self.searchNearby(coordinate: coordinate)
            }
            .store(in: &cancellables)

        locationManager.$authorizationStatus
            .sink { [weak self] status in
                guard let self else { return }
                if status == .authorizedWhenInUse || status == .authorizedAlways {
                    self.showLocationPermissionPrompt = false
                    self.locationManager.startUpdating()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension FieldBookingViewModel: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = Array(completer.results.prefix(5))
        Task { @MainActor [weak self] in
            self?.searchCompletions = results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Silently ignore completer errors
    }
}
