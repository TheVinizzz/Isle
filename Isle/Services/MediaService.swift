import AppKit
import Foundation
import Observation
import SwiftUI

/// Reads now-playing state from Apple Music + Spotify via DistributedNotificationCenter
/// (push-based, public API, works on macOS 14+ including 15.4+ entitlement era).
///
/// Playback control goes through AppleScript (osascript) — triggers a one-time
/// TCC Automation prompt on first use.
@MainActor
@Observable
final class MediaService {
    enum Source: Equatable {
        case none
        case spotify
        case appleMusic

        var bundleID: String? {
            switch self {
            case .spotify: return "com.spotify.client"
            case .appleMusic: return "com.apple.Music"
            case .none: return nil
            }
        }

        var displayName: String {
            switch self {
            case .spotify: return "Spotify"
            case .appleMusic: return "Apple Music"
            case .none: return ""
            }
        }

        var accentColor: NSColor {
            switch self {
            case .spotify: return NSColor(red: 0.118, green: 0.843, blue: 0.376, alpha: 1.0)
            case .appleMusic: return NSColor(red: 0.984, green: 0.227, blue: 0.435, alpha: 1.0)
            case .none: return .clear
            }
        }
    }

    private(set) var title: String = ""
    private(set) var artist: String = ""
    private(set) var album: String = ""
    private(set) var artwork: NSImage?
    private(set) var isPlaying: Bool = false
    private(set) var source: Source = .none
    /// Bumped whenever the playing track changes — drives view transitions.
    private(set) var trackChangeID: UUID = UUID()
    /// Vivid color extracted from current artwork — feeds the audio visualizer.
    private(set) var artworkAccent: Color = Color(nsColor: NSColor.systemBlue)

    private var observers: [NSObjectProtocol] = []
    private var artworkLoadTask: Task<Void, Never>?
    private var hasProbedInitialState = false

    func start() {
        let dnc = DistributedNotificationCenter.default()
        observers.append(
            dnc.addObserver(
                forName: Notification.Name("com.spotify.client.PlaybackStateChanged"),
                object: nil,
                queue: .main
            ) { [weak self] note in
                Task { @MainActor in self?.handleSpotify(note) }
            }
        )
        observers.append(
            dnc.addObserver(
                forName: Notification.Name("com.apple.Music.playerInfo"),
                object: nil,
                queue: .main
            ) { [weak self] note in
                Task { @MainActor in self?.handleAppleMusic(note) }
            }
        )
    }

    func stop() {
        let dnc = DistributedNotificationCenter.default()
        observers.forEach { dnc.removeObserver($0) }
        observers.removeAll()
        artworkLoadTask?.cancel()
    }

    // MARK: - Notification handlers

    private func handleSpotify(_ note: Notification) {
        guard let info = note.userInfo else { return }
        let state = info["Player State"] as? String ?? ""

        if state == "Stopped" {
            reset()
            return
        }

        let newTitle = info["Name"] as? String ?? ""
        let newArtist = info["Artist"] as? String ?? ""
        let trackChanged = (newTitle != title || newArtist != artist) && !newTitle.isEmpty

        source = .spotify
        title = newTitle
        artist = newArtist
        album = info["Album"] as? String ?? ""
        isPlaying = state == "Playing"

        if trackChanged { trackChangeID = UUID() }

        if let urlString = info["Artwork URL"] as? String,
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            loadArtwork(from: url)
        } else {
            // Recent Spotify builds dropped "Artwork URL" from the broadcast —
            // fall back to AppleScript to fetch the cover URL.
            Task { @MainActor [weak self] in
                await self?.fetchSpotifyArtwork()
            }
        }
    }

    private func fetchSpotifyArtwork() async {
        let script = """
        tell application "Spotify"
            try
                return artwork url of current track
            on error
                return ""
            end try
        end tell
        """
        guard let urlString = await runScriptCapturing(script),
              !urlString.isEmpty,
              let url = URL(string: urlString)
        else { return }
        loadArtwork(from: url)
    }

    private func handleAppleMusic(_ note: Notification) {
        guard let info = note.userInfo else { return }
        let state = info["Player State"] as? String ?? ""

        if state == "Stopped" {
            reset()
            return
        }

        let newTitle = info["Name"] as? String ?? ""
        let newArtist = info["Artist"] as? String ?? ""
        let trackChanged = (newTitle != title || newArtist != artist) && !newTitle.isEmpty

        source = .appleMusic
        title = newTitle
        artist = newArtist
        album = info["Album"] as? String ?? ""
        isPlaying = state == "Playing"
        // Apple Music doesn't ship artwork in the notification; would need an
        // AppleScript fetch for `raw data of artwork 1` (heavy, deferred).
        if trackChanged {
            trackChangeID = UUID()
            artwork = nil
        }
    }

    private func reset() {
        title = ""
        artist = ""
        album = ""
        artwork = nil
        isPlaying = false
        source = .none
        artworkAccent = Color(nsColor: NSColor.systemBlue)
    }

    private func loadArtwork(from url: URL) {
        artworkLoadTask?.cancel()
        artworkLoadTask = Task { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = NSImage(data: data),
                  !Task.isCancelled
            else { return }
            let accent = image.averageColor?.vibrant()
            await MainActor.run {
                self?.artwork = image
                if let accent {
                    self?.artworkAccent = Color(nsColor: accent)
                }
            }
        }
    }

    // MARK: - Playback control via AppleScript

    func togglePlayPause() { runScript(command: "playpause") }
    func nextTrack() { runScript(command: "next track") }
    func previousTrack() { runScript(command: "previous track") }

    private func runScript(command: String) {
        guard let appName = appleScriptAppName else { return }
        let source = "tell application \"\(appName)\" to \(command)"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        try? process.run()
    }

    private var appleScriptAppName: String? {
        switch source {
        case .spotify: return "Spotify"
        case .appleMusic: return "Music"
        case .none: return nil
        }
    }

    // MARK: - Initial state probe

    /// Lazily fetch the current playback state from Spotify and Apple Music.
    /// Called on first hover so the panel shows real data without requiring
    /// the user to advance a track to trigger a notification.
    func probeInitialStateIfNeeded() async {
        guard !hasProbedInitialState else { return }
        hasProbedInitialState = true

        if let result = await probeApp(name: "Spotify") {
            apply(result, source: .spotify)
            await fetchSpotifyArtwork()
            return
        }
        if let result = await probeApp(name: "Music") {
            apply(result, source: .appleMusic)
        }
    }

    private struct ProbeResult {
        let title: String
        let artist: String
        let album: String
        let isPlaying: Bool
    }

    private func apply(_ result: ProbeResult, source: Source) {
        let trackChanged = (result.title != title || result.artist != artist) && !result.title.isEmpty
        self.title = result.title
        self.artist = result.artist
        self.album = result.album
        self.isPlaying = result.isPlaying
        self.source = source
        if trackChanged { trackChangeID = UUID() }
    }

    private func probeApp(name: String) async -> ProbeResult? {
        let script = """
        if application "\(name)" is running then
            try
                tell application "\(name)"
                    set t to name of current track
                    set ar to artist of current track
                    set al to album of current track
                    set st to (player state as string)
                    return t & "‖" & ar & "‖" & al & "‖" & st
                end tell
            on error
                return ""
            end try
        else
            return ""
        end if
        """
        guard let output = await runScriptCapturing(script),
              !output.isEmpty
        else { return nil }
        let parts = output.components(separatedBy: "‖")
        guard parts.count == 4 else { return nil }
        return ProbeResult(
            title: parts[0],
            artist: parts[1],
            album: parts[2],
            isPlaying: parts[3].lowercased() == "playing"
        )
    }

    private func runScriptCapturing(_ script: String) async -> String? {
        await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]
            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe
            do {
                try process.run()
                process.waitUntilExit()
                let data = outPipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {
                return nil
            }
        }.value
    }
}
