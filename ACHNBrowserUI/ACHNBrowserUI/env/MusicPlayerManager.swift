//
//  File.swift
//  
//
//  Created by Thomas Ricouard on 24/05/2020.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation
import MediaPlayer
import SDWebImage
import Backend

public class MusicPlayerManager: ObservableObject {
    public static let shared = MusicPlayerManager()
    
    public enum PlayMode {
        case stopEnd, random, ordered
        
        mutating public func toggle() {
            switch self {
            case .stopEnd:
                self = .random
            case .random:
                self = .ordered
            case .ordered:
                self = .stopEnd
            }
        }
    }
    
    @Published public var kkTracks: [String: Song] = [:]
    @Published public var hourlyMusics: [String: HourlyMusic] = [:]
    public var sortedHourlyMusics: [HourlyMusic] {
        hourlyMusics.values.map{ $0 }.sorted(by: \.id).reversed()
    }
    
    @Published public var currentSongItem: Item?
    @Published public var currentSong: Song? {
        didSet {
            if let song = currentSong {
                currentHourlyMusic = nil
                currentSongItem = matchItemFrom(song: song)
                let musicURL = ACNHApiService.makeURL(endpoint: .music(id: song.id))
                player?.pause()
                player = AVPlayer(url: musicURL)
                
                setupBackgroundPlay()
            }
        }
    }
    
    @Published public var currentHourlyMusic: HourlyMusic? {
        didSet {
            if let music = currentHourlyMusic {
                currentSong = nil
                currentSongItem = nil
                
                let musicURL = ACNHApiService.makeURL(endpoint: .hourly(id: music.id))
                player?.pause()
                player = AVPlayer(url: musicURL)
            }
        }
    }
    
    @Published public var isPlaying = false {
        didSet {
            isPlaying ? player?.play() : player?.pause()
            MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .paused
        }
    }
    
    @Published public var playmode = PlayMode.stopEnd
    
    private var songsCancellable: AnyCancellable?
    private var hourlyMusicCancellable: AnyCancellable?
    private var player: AVPlayer?
    
    init() {
        songsCancellable = ACNHApiService
            .fetch(endpoint: .songs)
            .replaceError(with: [:])
            .eraseToAnyPublisher()
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] songs in self?.kkTracks = songs })
        
        hourlyMusicCancellable = ACNHApiService
            .fetch(endpoint: .backgroundmusic)
            .replaceError(with: [:])
            .eraseToAnyPublisher()
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] musics in self?.hourlyMusics = musics })
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                               object: player?.currentItem,
                                               queue: .main) { [weak self] _ in
                                                guard let weakself = self else { return }
                                                switch weakself.playmode {
                                                case .stopEnd:
                                                    self?.isPlaying = false
                                                case .random:
                                                    self?.isPlaying = false
                                                    self?.currentSong = self?.kkTracks.randomElement()?.value
                                                    self?.isPlaying = true
                                                case .ordered:
                                                    self?.isPlaying = false
                                                    self?.next()
                                                }
        }
        self.setupRemoteCommands()
    }
    
    public func next() {
        changeSong(newIndex: 1)
    }
    
    public func previous() {
        changeSong(newIndex: -1)
    }
    
    private func changeSong(newIndex: Int) {
        if let current = currentSongItem,
            var index = Items.shared.categories[.music]?.firstIndex(of: current) {
            index += newIndex
            if index > 0 && index < Items.shared.categories[.music]?.count ?? 0 {
                if let newSong = Items.shared.categories[.music]?[index],
                    let song = matchSongFrom(item: newSong) {
                    currentSong = song
                    isPlaying = true
                }
            }
        } else if let current = currentHourlyMusic,
            var index = sortedHourlyMusics.firstIndex(where: { $0.id == current.id }) {
            index += newIndex
            if index > 0 && index < hourlyMusics.count {
                currentHourlyMusic = sortedHourlyMusics[index]
                isPlaying = true
            }
        }
    }
    
    public func matchSongFrom(item: Item) -> Song? {
        kkTracks[item.filename ?? ""]
    }
    
    public func matchItemFrom(song: Song) -> Item? {
        Items.shared.categories[.music]?.first(where: { $0.filename == song.fileName })
    }
    
    private func setupRemoteCommands() {
        MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] event in
            if self?.isPlaying == false {
                self?.isPlaying = true
                return .success
            }
            return .commandFailed
        }
        
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] event in
            if self?.isPlaying == true {
                self?.isPlaying = false
                return .success
            }
            return .commandFailed
        }
        
        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { [weak self] event in
            self?.next()
            return .success
        }
        
        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { [weak self] event in
            self?.previous()
            return .success
        }
    }
    
    private func setupBackgroundPlay() {
        if let filename = currentSongItem?.finalImage {
            SDWebImageDownloader.shared.downloadImage(with: ImageService.computeUrl(key: filename)) { (image, _, _, _) in
                if let image = image {
                    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .longFormAudio, options: [])
                    try? AVAudioSession.sharedInstance().setActive(true, options: [])
                    
                    UIApplication.shared.beginReceivingRemoteControlEvents()
                    
                    let info: [String: Any] =
                        [MPMediaItemPropertyArtist: "K.K Slider",
                         MPMediaItemPropertyAlbumTitle: "K.K Slider",
                         MPMediaItemPropertyTitle: self.currentSongItem?.name ?? "",
                         MPMediaItemPropertyArtwork: MPMediaItemArtwork(boundsSize: CGSize(width: 100, height: 100),
                                                                        requestHandler: { (size: CGSize) -> UIImage in
                            return image
                         })]
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                }
            }
        }
    }
}
