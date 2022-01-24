//
//  ItemDetailView.swift
//  Aarlo
//
//  Created by martinhartl on 12.01.22.
//

import SwiftUI

struct ItemDetailView: View {
    let link: Link
    @ObservedObject private var linkStore: LinkStore
    @ObservedObject private var tagStore: TagStore

    @Binding var appState: AppState

    init(
        link: Link,
        linkStore: LinkStore,
        tagStore: TagStore,
        appState: Binding<AppState>
    ) {
        self.link = link
        self.linkStore = linkStore
        self.tagStore = tagStore
        self._appState = appState
    }

    private let pasteboard = DefaultPasteboard()

    var body: some View {
#if os(macOS)
        HSplitView {
            WebView(data: WebViewData(url: link.url))
                .toolbar {
                    Spacer()
                    Button {
                        appState.showLinkEditorSidebar.toggle()
                    } label: {
                        Label("Show Edit Link", systemImage: "sidebar.right")
                    }
                    // TODO: Add keyboard shortcut

                }
            if appState.showLinkEditorSidebar {
                LinkEditView(link: link, linkStore: linkStore, tagStore: tagStore)
                    .frame(minWidth: 220, idealWidth: 400, maxWidth: 500)
            }
        }
#else
        WebView(data: WebViewData(url: link.url))
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        UIApplication.shared.open(
                            link.url,
                            options: [:],
                            completionHandler: nil
                        )
                    }, label: {
                        Label("Open in Safari ", systemImage: "safari")
                    })
                }
                // TODO: Show share sheet instead
                ToolbarItem(placement: .bottomBar) {
                    Button(action: {
                        pasteboard.copyToPasteboard(string: link.url.absoluteString)
                    }, label: {
                        Label("Copy to Clipboard ", systemImage: "paperclip.circle")
                    })
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        LinkEditView(link: link, linkStore: linkStore, tagStore: tagStore)
                    } label: {
                        Label("Edit", systemImage: "pencil.circle")
                    }

                }
            }
            .navigationTitle(link.title ?? "")
#endif
    }
}

#if DEBUG
struct ItemDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ItemDetailView(
            link: Link.mock,
            linkStore: LinkStore.mock,
            tagStore: .mock,
            appState: AppState.stateMock
        )
    }
}
#endif
