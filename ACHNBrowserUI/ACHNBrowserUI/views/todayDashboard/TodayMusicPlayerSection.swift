//
//  TodayMusicPlayerSection.swift
//  ACHNBrowserUI
//
//  Created by Thomas Ricouard on 24/05/2020.
//  Copyright © 2020 Thomas Ricouard. All rights reserved.
//

import SwiftUI
import SwiftUIKit
import Combine
import Backend

struct TodayMusicPlayerSection: View {
    @EnvironmentObject private var musicPlayerManager: MusicPlayerManager
    @EnvironmentObject private var items: Items
    
    @State private var presentedSheet: Sheet.SheetType?
    @State private var isNavigationActive = false
    @State private var trackMode = TrackMode.tracks
    
    enum TrackMode: String, CaseIterable {
        case tracks = "K.K Slider"
        case hourly = "Hourly music"
    }
    
    var body: some View {
        Section(header: SectionHeaderView(text: "Music player",
                                          icon: "music.note"))
        {
            if musicPlayerManager.currentSongItem != nil || musicPlayerManager.currentHourlyMusic != nil {
                NavigationLink(destination: songsList, isActive: $isNavigationActive) {
                    if trackMode == .tracks && musicPlayerManager.currentSongItem != nil {
                        ItemRowView(displayMode: .largeNoButton, item: musicPlayerManager.currentSongItem!)
                    } else if trackMode == .hourly && musicPlayerManager.currentHourlyMusic != nil {
                        Text(musicPlayerManager.currentHourlyMusic!.localizedName)
                            .style(appStyle: .rowTitle)
                    } else {
                        RowLoadingView(isLoading: .constant(true))
                    }
                }
                playerView
            } else {
                RowLoadingView(isLoading: .constant(true))
            }
        }.onAppear {
            if self.musicPlayerManager.currentSong == nil && self.musicPlayerManager.currentHourlyMusic == nil,
                let random = self.items.categories[.music]?.randomElement(),
                let song = self.musicPlayerManager.matchSongFrom(item: random) {
                self.musicPlayerManager.currentSong = song
            }
        }
    }
    
    
    private var playerView: some View {
        HStack(alignment: .center, spacing: 32) {
            Spacer()
            Button(action: {
                self.musicPlayerManager.previous()
            }) {
                Image(systemName: "backward.fill")
                    .imageScale(.large)
                    .foregroundColor(.acText)
            }
            .buttonStyle(PlainButtonStyle())
            Button(action: {
                self.musicPlayerManager.isPlaying.toggle()
            }) {
                Image(systemName: musicPlayerManager.isPlaying ? "pause.fill" : "play.fill")
                    .imageScale(.large)
                    .foregroundColor(.acText)
            }
            .buttonStyle(PlainButtonStyle())
            Button(action: {
                self.musicPlayerManager.next()
            }) {
                Image(systemName: "forward.fill")
                    .imageScale(.large)
                    .foregroundColor(.acText)
            }
            .buttonStyle(PlainButtonStyle())
            Button(action: {
                self.musicPlayerManager.playmode.toggle()
            }) {
                playModeIcon
                    .imageScale(.large)
                    .foregroundColor(.acText)
            }
            .buttonStyle(PlainButtonStyle())
            Spacer()
        }
    }
    
    private var picker: some View {
        Picker("", selection: $trackMode) {
            ForEach(TrackMode.allCases, id: \.self) { mode in
                Text(mode.rawValue.capitalized)
            }
        }.pickerStyle(SegmentedPickerStyle())
        
    }
    
    private var songsList: some View {
        List {
            Section(header: picker) {
                if trackMode == .tracks {
                    ForEach(items.categories[.music] ?? []) { item in
                        ItemRowView(displayMode: .largeNoButton, item: item)
                            .onTapGesture {
                                if let song = self.musicPlayerManager.matchSongFrom(item: item) {
                                    self.musicPlayerManager.currentSong = song
                                    self.musicPlayerManager.isPlaying = true
                                    self.isNavigationActive = false
                                }
                        }
                    }
                } else if trackMode == .hourly {
                    ForEach(musicPlayerManager.sortedHourlyMusics) { music in
                        Text(music.localizedName).style(appStyle: .rowTitle)
                            .onTapGesture {
                                self.musicPlayerManager.currentHourlyMusic = music
                                self.musicPlayerManager.isPlaying = true
                                self.isNavigationActive = false
                        }
                    }
                }
            }
        }
        .navigationBarTitle(Text("Tracks"))
        .listStyle(GroupedListStyle())
        .environment(\.horizontalSizeClass, .regular)
        .sheet(item: $presentedSheet, content: { Sheet(sheetType: $0) })
    }

    private var playModeIcon: Image {
        switch musicPlayerManager.playmode {
        case .random:
            return Image(systemName: "shuffle")
        case .ordered:
            return Image(systemName: "forward.end.alt.fill")
        case .stopEnd:
            return Image(systemName: "stop.fill")
        }
    }
}

struct TodayMusicPlayer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                TodayMusicPlayerSection()
            }
            .listStyle(GroupedListStyle())
            .environment(\.horizontalSizeClass, .regular)
            .environmentObject(MusicPlayerManager.shared)
            .environmentObject(Items.shared)
        }
    }
}
