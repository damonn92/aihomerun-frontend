import SwiftUI
import MapKit

// MARK: - Map Snapshot Cache (memory + disk)

private let snapshotCache = NSCache<NSString, UIImage>()

/// Limits concurrent MKMapSnapshotter requests to avoid overloading MapKit
private actor SnapshotThrottler {
    private var running = 0
    private let maxConcurrent = 2
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        if running < maxConcurrent {
            running += 1
            return
        }
        await withCheckedContinuation { cont in
            waiters.append(cont)
        }
    }

    func release() {
        if let next = waiters.first {
            waiters.removeFirst()
            next.resume()
        } else {
            running -= 1
        }
    }
}

private let throttler = SnapshotThrottler()

/// Disk cache directory for map snapshots
private let diskCacheDir: URL = {
    let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("MapSnapshots", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
}()

// MARK: - Map Snapshot View

struct MapSnapshotView: View {
    let coordinate: CLLocationCoordinate2D
    var height: CGFloat = 120
    var span: Double = 0.005

    @State private var snapshot: UIImage?
    @State private var isLoading = true
    @Environment(\.colorScheme) private var colorScheme

    private var cacheKey: String {
        "\(coordinate.latitude),\(coordinate.longitude)-\(colorScheme == .dark ? "d" : "l")"
    }

    var body: some View {
        ZStack {
            // Background placeholder
            LinearGradient(
                colors: [Color.hrBlue.opacity(0.15), Color.hrCard],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            if let snapshot {
                Image(uiImage: snapshot)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity.animation(.easeIn(duration: 0.25)))
            } else if isLoading {
                ShimmerView()
            }
        }
        .frame(height: height)
        .clipped()
        .task(id: cacheKey) {
            await loadSnapshot()
        }
    }

    private func loadSnapshot() async {
        let nsKey = cacheKey as NSString

        // 1. Memory cache
        if let cached = snapshotCache.object(forKey: nsKey) {
            snapshot = cached
            isLoading = false
            return
        }

        // 2. Disk cache
        let diskURL = diskCacheDir.appendingPathComponent(
            cacheKey.replacingOccurrences(of: ",", with: "_")
                .replacingOccurrences(of: "-", with: "_") + ".jpg"
        )
        if let data = try? Data(contentsOf: diskURL),
           let diskImage = UIImage(data: data) {
            snapshotCache.setObject(diskImage, forKey: nsKey)
            snapshot = diskImage
            isLoading = false
            return
        }

        // 3. Throttled network fetch
        await throttler.acquire()
        defer { Task { await throttler.release() } }

        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
        )
        // Smaller size for faster rendering (cards are small)
        options.size = CGSize(width: 240, height: height * 1.5)
        options.mapType = .mutedStandard
        options.traitCollection = UITraitCollection(userInterfaceStyle: colorScheme == .dark ? .dark : .light)
        options.showsBuildings = false

        let snapshotter = MKMapSnapshotter(options: options)

        do {
            let result = try await snapshotter.start()
            let image = drawPin(on: result)

            // Save to memory cache
            snapshotCache.setObject(image, forKey: nsKey)

            // Save to disk cache (JPEG, background)
            Task.detached(priority: .utility) {
                if let jpegData = image.jpegData(compressionQuality: 0.7) {
                    try? jpegData.write(to: diskURL, options: .atomic)
                }
            }

            await MainActor.run {
                self.snapshot = image
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    /// Draw a pin marker at the center of the snapshot
    private func drawPin(on result: MKMapSnapshotter.Snapshot) -> UIImage {
        let image = result.image
        let point = result.point(for: coordinate)

        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { ctx in
            image.draw(at: .zero)

            // Pin shadow
            let shadowRect = CGRect(
                x: point.x - 8,
                y: point.y - 2,
                width: 16,
                height: 6
            )
            ctx.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.3).cgColor)
            ctx.cgContext.fillEllipse(in: shadowRect)

            // Pin circle
            let pinSize: CGFloat = 18
            let pinRect = CGRect(
                x: point.x - pinSize / 2,
                y: point.y - pinSize,
                width: pinSize,
                height: pinSize
            )
            ctx.cgContext.setFillColor(UIColor(red: 0.078, green: 0.494, blue: 1.0, alpha: 1.0).cgColor)
            ctx.cgContext.fillEllipse(in: pinRect)

            // Pin white border
            ctx.cgContext.setStrokeColor(UIColor.white.cgColor)
            ctx.cgContext.setLineWidth(2.5)
            ctx.cgContext.strokeEllipse(in: pinRect)

            // Pin inner dot
            let dotSize: CGFloat = 5
            let dotRect = CGRect(
                x: point.x - dotSize / 2,
                y: point.y - pinSize / 2 - dotSize / 2,
                width: dotSize,
                height: dotSize
            )
            ctx.cgContext.setFillColor(UIColor.white.cgColor)
            ctx.cgContext.fillEllipse(in: dotRect)
        }
    }
}

// MARK: - Shimmer Effect

private struct ShimmerView: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                stops: [
                    .init(color: Color.primary.opacity(0.03), location: max(0, phase - 0.3)),
                    .init(color: Color.primary.opacity(0.08), location: phase),
                    .init(color: Color.primary.opacity(0.03), location: min(1, phase + 0.3))
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 2
            }
        }
    }
}
