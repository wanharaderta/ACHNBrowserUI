//
//  CollectionListView.swift
//  ACHNBrowserUI
//
//  Created by Thomas Ricouard on 08/04/2020.
//  Copyright © 2020 Thomas Ricouard. All rights reserved.
//

import SwiftUI

struct CollectionListView: View {
    enum Tabs: String, CaseIterable {
        case items, villagers
    }

    @EnvironmentObject private var collection: CollectionViewModel
    @State private var selectedTab: Tabs = .items
    
    private var itemsList: some View {
        List(collection.items) { item in
            NavigationLink(destination: ItemDetailView(itemsViewModel: ItemsViewModel(categorie: item.appCategory ?? .housewares),
                                                       itemViewModel: ItemDetailViewModel(item: item))) {
                                                        ItemRowView(item: item)
            }
        }
    }
    
    private var villagersList: some View {
        List(collection.villagers) { villager in
            NavigationLink(destination: VillagerDetailView(villager: villager,
                                                           villagersViewModel: VillagersViewModel())) {
                                                            VillagerRowView(villager: villager)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Picker(selection: $selectedTab, label: Text("")) {
                    ForEach(Tabs.allCases, id: \.self) { tab in
                        Text(tab.rawValue.capitalized)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == .items {
                    itemsList
                } else if selectedTab == .villagers {
                    villagersList
                }
            }
            .overlay(Group {
                if collection.items.isEmpty {
                    Text("Tap the stars to start collecting!")
                        .foregroundColor(.secondary)
                }
            })
            .background(Color.dialogue)
            .navigationBarTitle(Text("Collection"),
                                displayMode: .inline)
        }
    }
}