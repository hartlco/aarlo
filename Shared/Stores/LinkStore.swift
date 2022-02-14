//
//  LinkStore.swift
//  Aarlo
//
//  Created by martinhartl on 05.01.22.
//

import Foundation
import Combine
import SwiftUI

enum ListType: Hashable, Equatable, Sendable {
    case all
    case tags
    case tagScoped(Tag)
}

@MainActor
final class LinkStore: ObservableObject {
    enum Action {
        case load(ListType)
        case loadMoreIfNeeded(ListType, Link)
        case changeSearchText(String, listType: ListType)
        case search(ListType)
        case setShowLoadingError(Bool)
        case add(PostLink)
        case delete(Link)
        case update(Link)
    }

    struct State {
        // TODO: Move into subStore
        struct ListState {
            var links: [Link] = []
            var tagScope: String?
            var canLoadMore = false
            var searchText = ""
            var didLoad = false
        }

        var isLoading = false
        var listStates: [ListType: ListState] = [:]
        var showLoadingError = false
    }

    private let client: BookmarkClient

    @Published private var state: State

    init(
        client: BookmarkClient,
        tagScope: String? = nil
    ) {
        self._state = Published(initialValue: State())
        self.client = client
    }

    var showLoadingError: Binding<Bool> {
        Binding { [weak self] in
            return self?.state.showLoadingError ?? false
        } set: { [weak self] value in
            guard let self = self else { return }
            self.reduce(.setShowLoadingError(value))
        }
    }

    func searchText(for type: ListType) -> String {
        let listState = state.listStates[type]
        return listState?.searchText ?? ""
    }

    @MainActor func reduce(_ action: Action) {
        switch action {
        case let .search(type):
            Task {
                do {
                    try await load(type: type)
                } catch {
                    state.showLoadingError = true
                }
            }
        case let .load(type):
            Task {
                do {
                    try await load(type: type)
                } catch {
                    state.showLoadingError = true
                }
            }
        case let .loadMoreIfNeeded(type, link):
            Task {
                do {
                    try await loadMoreIfNeeded(type: type, link: link)
                } catch {
                    state.showLoadingError = true
                }
            }
        case let .changeSearchText(string, type):
            var listState = state.listStates[type] ?? State.ListState()
            listState.searchText = string
            state.listStates[type] = listState

            if string.isEmpty {
                reduce(.load(type))
            }
        case let .setShowLoadingError(show):
            state.showLoadingError = show
        case let .delete(link):
            Task {
                do {
                    try await delete(link: link)
                } catch {
                    state.showLoadingError = true
                }
            }
        case let .update(link):
            Task {
                do {
                    try await update(link: link)
                } catch {
                    state.showLoadingError = true
                }
            }
        case let .add(link):
            Task {
                do {
                    try await add(link: link)
                } catch {
                    state.showLoadingError = true
                }
            }
        }
    }

    var isLoading: Bool {
        state.isLoading
    }

    func didLoad(listType: ListType) -> Bool {
        state.listStates[listType]?.didLoad ?? false
    }

    func links(for listType: ListType) -> [Link] {
        state.listStates[listType]?.links ?? []
    }

    func link(for ID: String) -> Link? {
        for listStates in state.listStates {
            for link in listStates.value.links where link.id == ID {
                return link
            }
        }

        return nil
    }

    func canLoadMore(for listType: ListType) -> Bool {
        state.listStates[listType]?.canLoadMore ?? false
    }

    private func scopedTages(for type: ListType) -> [String] {
        switch type {
        case .all:
            return []
        case .tagScoped(let tag):
            return [tag.name]
        case .tags:
            return []
        }
    }

#if DEBUG
    static let mock = LinkStore(client: MockClient())
#endif

    @MainActor private func load(type: ListType) async throws {
        guard state.isLoading == false else { return }

        defer {
            state.isLoading = false
        }

        var listState = state.listStates[type] ?? State.ListState()
        listState.didLoad = true

        state.isLoading = true

        listState.links = try await client.load(
            filteredByTags: scopedTages(for: type),
            searchTerm: searchText(for: type)
        )

        listState.canLoadMore = listState.links.count == client.pageSize
        state.listStates[type] = listState
    }

    @MainActor private func loadMoreIfNeeded(type: ListType, link: Link) async throws {
        guard state.isLoading == false else { return }

        var listState = state.listStates[type] ?? State.ListState()

        guard link.id == listState.links.last?.id else { return }

        defer {
            state.isLoading = false
        }

        state.isLoading = true

        let links = try await client.loadMore(
            offset: listState.links.count,
            filteredByTags: scopedTages(for: type), searchTerm: searchText(for: type)
        )
        listState.links.append(contentsOf: links)

        listState.canLoadMore = links.count == client.pageSize
        state.listStates[type] = listState
    }

    // TODO: local add for tags, parse response to maybe get ID?
    @MainActor private func add(link: PostLink) async throws {
        guard state.isLoading == false else { return }
        state.isLoading = true

        defer {
            state.isLoading = false
        }

        try await client.createLink(link: link)
    }

    @MainActor private func update(link: Link) async throws {
        guard state.isLoading == false else { return }
        state.isLoading = true

        defer {
            state.isLoading = false
        }

        try await client.updateLink(link: link)

        for (key, value) in state.listStates {
            state.listStates[key] = updated(link: link, from: value)
        }
    }

    @MainActor private func delete(link: Link) async throws {
        guard state.isLoading == false else { return }
        state.isLoading = true

        defer {
            state.isLoading = false
        }

        try await client.deleteLink(link: link)

        for (key, value) in state.listStates {
            state.listStates[key] = deleted(link: link, from: value)
        }
    }

    private func updated(link: Link, from listState: State.ListState) -> State.ListState {
        var listState = listState
        if let index = listState.links.firstIndex(where: { $0.id == link.id }) {
            listState.links[index] = link
        }

        return listState
    }

    private func deleted(link: Link, from listState: State.ListState) -> State.ListState {
        var listState = listState
        listState.links.removeAll {
            link == $0
        }

        return listState
    }
}
