import SwiftUI
import AVFoundation
import os.log

private let viewLog = Logger(subsystem: "com.aihomerun.app", category: "VideoReplay")

// MARK: - UIKit Player Layer (UIViewRepresentable)

struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }

    /// UIView subclass that uses AVPlayerLayer as its backing layer
    class PlayerUIView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

// MARK: - Video Replay View (Embeddable Card)

struct VideoReplayView: View {
    let videoURL: URL
    @StateObject private var vm = VideoReplayViewModel()
    @StateObject private var poseVM = PoseOverlayViewModel()
    @State private var showControls = true
    @State private var hideTask: Task<Void, Never>?
    @State private var show3D = false
    @State private var _skeleton3DVM: AnyObject?  // Actually Skeleton3DViewModel (iOS 17+), stored as Any to avoid availability error

    var body: some View {
        VStack(spacing: 0) {
            // Video area
            ZStack {
                Color.black

                if let error = vm.loadError {
                    errorOverlay(error)
                } else {
                    zoomablePlayer
                    controlsOverlay
                }
            }
            .aspectRatio(16.0 / 9.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .onTapGesture {
                if !poseVM.isDrawingMode { toggleControlsVisibility() }
            }

            // Timeline + speed controls below video
            VStack(spacing: 10) {
                VideoTimelineView(
                    progress: vm.progress,
                    currentTime: vm.currentTimeFormatted,
                    duration: vm.durationFormatted,
                    onSeek: { frac in vm.seek(to: frac) },
                    onDragStart: {
                        if vm.isPlaying {
                            vm.player.pause()
                        }
                    },
                    onDragEnd: {
                        if vm.isPlaying {
                            vm.player.rate = vm.playbackRate
                        }
                    }
                )

                // Bottom bar: frame step buttons + speed + fullscreen
                HStack(spacing: 0) {
                    frameStepButtons
                    Spacer()
                    speedPicker
                    Spacer()
                    fullScreenButton
                }

                // Pose analysis toolbar
                PoseToolbar(poseVM: poseVM)
            }
            .padding(.horizontal, 4)
            .padding(.top, 8)
        }
        .onAppear {
            poseDebugLog("[VideoReplay] onAppear — \(videoURL.lastPathComponent)")
            vm.loadVideo(url: videoURL)
            poseVM.startAnalysis(videoURL: videoURL)
        }
        .onDisappear {
            poseDebugLog("[VideoReplay] onDisappear — only pausing player")
            vm.player.pause()
        }
        .task {
            poseDebugLog("[VideoReplay] .task fired — launching pose analysis")
            await poseVM.runAnalysis(videoURL: videoURL)
        }
        .onChange(of: vm.currentTime) { newTime in
            poseVM.updatePose(forTime: newTime)
        }
        .fullScreenCover(isPresented: $vm.isFullScreen) {
            FullScreenVideoView(vm: vm, poseVM: poseVM)
        }
    }

    // MARK: - Zoomable Player + Skeleton Overlay

    private var zoomablePlayer: some View {
        ZStack {
            if show3D, #available(iOS 17, *), let skel3D = _skeleton3DVM as? Skeleton3DViewModel {
                Skeleton3DView(vm: skel3D, currentTime: vm.currentTime)
            } else {
                PlayerLayerView(player: vm.player)
                SkeletonOverlayView(poseVM: poseVM, currentTime: vm.currentTime)
            }

            // 2D/3D toggle button (top-right corner, only on iOS 17+)
            if #available(iOS 17, *) {
                VStack {
                    HStack {
                        Spacer()
                        toggle3DButton
                    }
                    Spacer()
                }
                .padding(6)
            }
        }
        .scaleEffect(show3D ? 1.0 : vm.zoomScale)
        .offset(show3D ? .zero : vm.panOffset)
        .clipped()
        .gesture(poseVM.isDrawingMode || show3D ? nil : magnificationGesture)
        .gesture(poseVM.isDrawingMode || show3D ? nil : panGesture)
        .gesture(poseVM.isDrawingMode || show3D ? nil : doubleTapGesture)
    }

    @available(iOS 17, *)
    private var toggle3DButton: some View {
        Button {
            withAnimation(.spring(duration: 0.3)) {
                show3D.toggle()
            }
            // Lazy-init 3D VM and start analysis
            if show3D && _skeleton3DVM == nil {
                let skel = Skeleton3DViewModel()
                _skeleton3DVM = skel
                Task {
                    await skel.runAnalysis3D(videoURL: videoURL)
                }
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: show3D ? "square.2.layers.3d.top.filled" : "cube.transparent")
                    .font(.system(size: 10, weight: .semibold))
                Text(show3D ? "3D" : "2D")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(show3D ? Color.hrBlue : .white.opacity(0.7))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(show3D ? Color.hrBlue.opacity(0.2) : Color.black.opacity(0.4))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                vm.zoomScale = min(max(value, 1.0), 5.0)
            }
            .onEnded { _ in
                vm.clampZoom()
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard vm.zoomScale > 1.01 else { return }
                vm.panOffset = value.translation
            }
            .onEnded { _ in
                if vm.zoomScale <= 1.01 {
                    vm.panOffset = .zero
                }
            }
    }

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded { vm.toggleZoom() }
    }

    // MARK: - Controls Overlay (play/pause centered)

    @ViewBuilder
    private var controlsOverlay: some View {
        if showControls && !poseVM.isDrawingMode {
            ZStack {
                // Gradient at bottom for readability
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                }

                // Center play/pause button
                Button {
                    vm.togglePlayPause()
                    scheduleHide()
                } label: {
                    Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 8)
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.2), value: showControls)
            .allowsHitTesting(showControls)
        }
    }

    // MARK: - Frame Step Buttons

    private var frameStepButtons: some View {
        HStack(spacing: 4) {
            Button { vm.stepBackward() } label: {
                Image(systemName: "backward.frame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)

            Button { vm.stepForward() } label: {
                Image(systemName: "forward.frame.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 36, height: 32)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Speed Picker

    private var speedPicker: some View {
        HStack(spacing: 4) {
            ForEach(VideoReplayViewModel.speeds, id: \.self) { rate in
                Button {
                    vm.setSpeed(rate)
                } label: {
                    Text(speedLabel(rate))
                        .font(.system(size: 11, weight: .semibold).monospacedDigit())
                        .foregroundStyle(vm.playbackRate == rate ? .white : .white.opacity(0.45))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(vm.playbackRate == rate ? Color.hrBlue : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Full Screen Button

    private var fullScreenButton: some View {
        Button {
            vm.isFullScreen = true
        } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 36, height: 32)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Error Overlay

    private func errorOverlay(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "film.slash")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.3))
            Text(message)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func speedLabel(_ rate: Float) -> String {
        if rate == 1.0 { return "1x" }
        return String(format: "%.2gx", rate)
    }

    private func toggleControlsVisibility() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showControls.toggle()
        }
        if showControls { scheduleHide() }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
}

// MARK: - Full Screen Video View

struct FullScreenVideoView: View {
    @ObservedObject var vm: VideoReplayViewModel
    @ObservedObject var poseVM: PoseOverlayViewModel
    @State private var showControls = true
    @State private var hideTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Zoomable player + skeleton
            ZStack {
                PlayerLayerView(player: vm.player)
                SkeletonOverlayView(poseVM: poseVM, currentTime: vm.currentTime)
            }
            .scaleEffect(vm.zoomScale)
            .offset(vm.panOffset)
            .clipped()
            .ignoresSafeArea()
            .gesture(poseVM.isDrawingMode ? nil : magnificationGesture)
            .gesture(poseVM.isDrawingMode ? nil : panGesture)
            .gesture(poseVM.isDrawingMode ? nil : doubleTapGesture)
            .onTapGesture {
                if !poseVM.isDrawingMode { toggleControls() }
            }

            // Controls overlay
            if showControls {
                fullScreenControls
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .statusBarHidden(true)
        .onAppear { scheduleHide() }
        .onChange(of: vm.currentTime) { newTime in
            poseVM.updatePose(forTime: newTime)
        }
    }

    // MARK: Full-Screen Controls

    private var fullScreenControls: some View {
        ZStack {
            // Top gradient
            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.6), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
                Spacer()
            }

            // Bottom gradient + controls
            VStack {
                Spacer()

                VStack(spacing: 12) {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)

                    VStack(spacing: 10) {
                        VideoTimelineView(
                            progress: vm.progress,
                            currentTime: vm.currentTimeFormatted,
                            duration: vm.durationFormatted,
                            onSeek: { frac in vm.seek(to: frac) },
                            onDragStart: {
                                if vm.isPlaying { vm.player.pause() }
                            },
                            onDragEnd: {
                                if vm.isPlaying { vm.player.rate = vm.playbackRate }
                            }
                        )

                        HStack(spacing: 0) {
                            // Frame step
                            HStack(spacing: 8) {
                                Button { vm.stepBackward() } label: {
                                    Image(systemName: "backward.frame.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .frame(width: 40, height: 36)
                                }
                                .buttonStyle(.plain)

                                Button { vm.stepForward() } label: {
                                    Image(systemName: "forward.frame.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white.opacity(0.8))
                                        .frame(width: 40, height: 36)
                                }
                                .buttonStyle(.plain)
                            }

                            Spacer()

                            // Speed picker
                            HStack(spacing: 6) {
                                ForEach(VideoReplayViewModel.speeds, id: \.self) { rate in
                                    Button {
                                        vm.setSpeed(rate)
                                    } label: {
                                        Text(rate == 1.0 ? "1x" : String(format: "%.2gx", rate))
                                            .font(.system(size: 13, weight: .semibold).monospacedDigit())
                                            .foregroundStyle(vm.playbackRate == rate ? .white : .white.opacity(0.5))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(vm.playbackRate == rate ? Color.hrBlue : Color.white.opacity(0.1))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Spacer()

                            // Zoom reset
                            if vm.zoomScale > 1.1 {
                                Button {
                                    vm.resetZoom()
                                } label: {
                                    Text("1:1")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.7))
                                        .frame(width: 40, height: 36)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Pose toolbar in fullscreen
                        PoseToolbar(poseVM: poseVM)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }

            // Center play/pause
            if !poseVM.isDrawingMode {
                Button {
                    vm.togglePlayPause()
                    scheduleHide()
                } label: {
                    Image(systemName: vm.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.5), radius: 12)
                }
            }

            // Close button top-left
            VStack {
                HStack {
                    Button {
                        vm.isFullScreen = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showControls)
    }

    // MARK: Gestures

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in vm.zoomScale = min(max(value, 1.0), 5.0) }
            .onEnded { _ in vm.clampZoom() }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard vm.zoomScale > 1.01 else { return }
                vm.panOffset = value.translation
            }
            .onEnded { _ in
                if vm.zoomScale <= 1.01 { vm.panOffset = .zero }
            }
    }

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2).onEnded { vm.toggleZoom() }
    }

    // MARK: Helpers

    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.2)) { showControls.toggle() }
        if showControls { scheduleHide() }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) { showControls = false }
        }
    }
}
