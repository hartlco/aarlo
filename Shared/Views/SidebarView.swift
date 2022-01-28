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
    @State var showsSettings = false

    @ObservedObject var linkStore: LinkStore
    @EnvironmentObject var tagStore: TagStore

    init(
        isDefaultItemActive: Bool = true,
        linkStore: LinkStore
    ) {
        self._isDefaultItemActive = State(initialValue: isDefaultItemActive)
        self.linkStore = linkStore
    }

    var body: some View {
        ZStack {
            List {
                Section(header: "Links") {
                    NavigationLink(
                        destination: ContentView(
                            title: "Links",
                            linkStore: linkStore
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
                                title: tag.name,
                                linkStore: LinkStore(
                                    client: ShaarliClient(),
                                    tagScope: tag.name
                                )
                            )
                        ) {
                            Label(tag.name, systemImage: "tag")
                        }
                    }
                }
            }.listStyle(SidebarListStyle())
            #if os(iOS)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showsSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }
                        .sheet(
                            isPresented: $showsSettings,
                            onDismiss: nil,
                            content: {
                                SettingsView()
                            }
                        )
                    }
                }
            #endif
        }
        
    }
}

#if DEBUG
struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(
            isDefaultItemActive: false,
            linkStore: LinkStore.mock
        ).environmentObject(TagStore.mock)
    }
}
#endif
