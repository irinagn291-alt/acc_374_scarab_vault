import Foundation

enum WidgetIdentity {
    static let group = "group.com.scarabvault.expedition"
    static let kind = "com.scarabvault.expedition.progress"
    static let scheme = "scarabvault"
    static let route = "expedition"
    static let displayName = "Scarab Vault"
    static let emptyHint = "Open the first temple to begin."
    static let widgetName = "Expedition journal"
    static let widgetDescription = "Your next chamber and recovered artefacts."
    static let icon = "ladybug.fill"
    static let theme = "vault"
    static let accent: [Double] = [0.84, 0.7, 0.36]
    static let background: [Double] = [0.02, 0.14, 0.11]
    static let serif = true
    static var url: URL { URL(string: "\(scheme)://widget/\(route)")! }
    static func accepts(_ url: URL) -> Bool { url.scheme == scheme && url.host == "widget" && url.path == "/" + route }
}
