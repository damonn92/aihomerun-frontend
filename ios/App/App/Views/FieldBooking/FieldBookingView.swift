import SwiftUI
import MapKit

// MARK: - Field Booking View

struct FieldBookingView: View {
    @StateObject private var vm = FieldBookingViewModel()
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.hrBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Real MapKit map
                    FieldMapView(
                        fields: vm.filteredFields,
                        userLocation: vm.userCoordinate,
                        region: $vm.mapRegion,
                        onFieldTap: { vm.selectedField = $0 }
                    )
                    .frame(height: 220)

                    // Content list
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Location permission banner
                            if vm.showLocationPermissionPrompt {
                                locationPermissionBanner
                            }

                            // Search bar
                            FieldSearchBar(
                                searchText: $vm.searchText,
                                completions: vm.searchCompletions,
                                onSearch: { vm.searchAddress($0) },
                                onCompletionTap: { vm.selectCompletion($0) },
                                onClear: { vm.clearSearch() }
                            )

                            // Filters
                            filterRow

                            // Header
                            nearbyHeader

                            // Loading state
                            if vm.isSearching {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .tint(Color.hrBlue)
                                    Text("Searching for fields...")
                                        .font(.caption)
                                        .foregroundStyle(.primary.opacity(0.55))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            }

                            // No results
                            if vm.searchState == .noResults {
                                noResultsView
                            }

                            // Error
                            if case .error(let msg) = vm.searchState {
                                errorBanner(msg)
                            }

                            // Field cards
                            ForEach(vm.filteredFields) { field in
                                FieldCardView(field: field, appeared: appeared) {
                                    vm.selectedField = field
                                }
                            }

                            Spacer(minLength: 30)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Find a Field")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.hrBg.opacity(0.95), for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 4) {
                        Image(systemName: vm.locationManager.hasPermission ? "location.fill" : "location.slash")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(vm.locationManager.hasPermission ? Color.hrGreen : Color.hrOrange)
                        Text(vm.locationName)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary.opacity(0.60))
                    }
                }
            }
            .sheet(item: $vm.selectedField) { field in
                FieldDetailSheet(field: field)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            appeared = true
            vm.load()
        }
    }

    // MARK: - Location Permission Banner

    private var locationPermissionBanner: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.hrBlue.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.hrBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable Location")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                    Text("Find baseball fields near you automatically")
                        .font(.caption)
                        .foregroundStyle(.primary.opacity(0.60))
                }
                Spacer()
            }

            Button {
                vm.requestLocationPermission()
            } label: {
                Text("Continue")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.hrBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(16)
        .background(Color.hrCard)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.hrBlue.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Filter Row

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FieldFilter.allCases, id: \.self) { option in
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            vm.selectedFilter = option
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: option.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(option.rawValue)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(vm.selectedFilter == option ? Color.white : Color.primary.opacity(0.55))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            vm.selectedFilter == option
                            ? Color.hrBlue
                            : Color.hrSurface
                        )
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Nearby Header

    private var nearbyHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Nearby Fields")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.primary)
                Text("\(vm.filteredFields.count) results \u{00B7} sorted by distance")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.50))
            }
            Spacer()
        }
    }

    // MARK: - No Results

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 36))
                .foregroundStyle(.primary.opacity(0.35))
            Text("No Fields Found")
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary.opacity(0.6))
            Text("Try searching a different area or expanding your search radius.")
                .font(.caption)
                .foregroundStyle(.primary.opacity(0.50))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
            Text(message)
                .font(.footnote)
        }
        .foregroundStyle(Color.hrRed)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.hrRed.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.hrRed.opacity(0.20), lineWidth: 1)
        )
    }
}
