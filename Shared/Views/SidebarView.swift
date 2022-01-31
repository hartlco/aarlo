//
//  SidebarView.swift
//  Aarlo
//
//  Created by martinhartl on 07.01.22.
//

import SwiftUI
import SwiftUIX

struct SidebarView: View {
    @State private var isDefaultItemActive: Bool

    @EnvironmentObject var linkStore: LinkStore
    @EnvironmentObject var tagStore: TagStore
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var appStore: AppStore

    init(
        isDefaultItemActive: Bool = true
    ) {
        self._isDefaultItemActive = State(initialValue: isDefaultItemActive)
    }

    var body: some View {
        List {
            Section(header: "Links") {
                NavigationLink(
                    destination: ContentView(
                        title: "Links"
                    ),
                    isActive: $isDefaultItemActive
                ) {
                    Label("All", systemImage: "tray.2")
                }
                NavigationLink(
                    destination: TagListView(
                        tagStore: tagStore
                    )
                ) {
                    Label("Tags", systemImage: "tag")
                }
            }
            Section(header: "Favorites") {
                ForEach(tagStore.favoriteTags) { tag in
                    NavigationLink(
                        destination: ContentView(
                            title: tag.name
                        ).environmentObject(
                            LinkStore(
                                client: UniversalClient(settingsStore: settingsStore),
                                tagScope: tag.name
                            )
                        )
                    ) {
                        Label(tag.name, systemImage: "tag")
                    }
                }
            }
        }
        .listStyle(SidebarListStyle())
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    appStore.reduce(.showSettings)
                } label: {
                    Label("Settings", systemImage: "gear")
                }
                .sheet(
                    isPresented: appStore.showsSettings,
                    content: {
                        SettingsView()
                    }
                )
            }
        }
#endif
        .onAppear {
            if settingsStore.isLoggedOut {
                appStore.reduce(.showSettings)
            }
        }
        .equatable(by: tagStore.favoriteTags)
    }
}

#if DEBUG
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(
            isDefaultItemActive: false
        ).environmentObject(TagStore.mock).environmentObject(LinkStore.mock)
    }
}
#endif
