import Foundation
import Types

public final class NavigationState: ObservableObject {
    #if os(macOS)
        @Published public var selectedListType: ListType = .all {
            didSet {
                print("Didset selectedListType: \(selectedListType)")
            }
        }
    #else
        @Published public var selectedListType: ListType? {
            didSet {
                print("Didset selectedListType: \(selectedListType)")
            }
        }
    #endif

    @Published public var showsSettings = false {
        didSet {
            if showsSettings {
                #if os(macOS)
                    WindowRoutes.settings.open()
                #endif
            }
        }
    }

    @Published public var selectedLink: Link? {
        didSet {
            print("Didset selectedLink: \(selectedLink?.url.absoluteString ?? "No URL")")
        }
    }
    
    @Published public var showLinkEditorSidebar = false
    
    public init() { }
}
