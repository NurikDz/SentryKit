// PluginProtocol.swift
// SentryKit
//
// Plugin system for extending SentryKit functionality.
// Plugins are loaded from ~/Library/Application Support/SentryKit/Plugins/

import Foundation

// MARK: - Plugin Protocol

/// Protocol that all SentryKit plugins must conform to.
/// Plugins are loaded as bundles (.bundle) from the plugins directory.
@objc public protocol SentryKitPlugin: NSObjectProtocol {

    /// Unique identifier for the plugin.
    var pluginIdentifier: String { get }

    /// Display name of the plugin.
    var pluginName: String { get }

    /// Version string of the plugin.
    var pluginVersion: String { get }

    /// Brief description of what the plugin does.
    var pluginDescription: String { get }

    /// Called when the plugin is loaded.
    func pluginDidLoad()

    /// Called when the plugin is about to be unloaded.
    func pluginWillUnload()

    /// Called after each permission scan with the latest data.
    @objc optional func didScanPermissions(_ permissions: [[String: Any]])

    /// Called when a permission changes.
    @objc optional func permissionDidChange(service: String, client: String, oldValue: Int, newValue: Int)

    /// Returns custom menu items to add to the app's menu.
    @objc optional func customMenuItems() -> [[String: Any]]

    /// Returns custom toolbar items.
    @objc optional func customToolbarItems() -> [[String: Any]]

    /// Called to generate a custom report section.
    @objc optional func generateReportSection(permissions: [[String: Any]]) -> String?
}

// MARK: - Plugin Manager

/// Manages loading, unloading, and communicating with plugins.
final class PluginManager: ObservableObject {

    static let shared = PluginManager()

    @Published var loadedPlugins: [PluginInfo] = []
    @Published var errors: [String] = []

    private var pluginInstances: [String: SentryKitPlugin] = [:]
    private var loadedBundles: [String: Bundle] = [:]

    /// Information about a loaded plugin.
    struct PluginInfo: Identifiable {
        let id: String
        let name: String
        let version: String
        let description: String
        let bundlePath: String
        var isEnabled: Bool
    }

    private var pluginsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("SentryKit/Plugins", isDirectory: true)
    }

    private init() {}

    // MARK: - Public API

    /// Discovers and loads all plugins from the plugins directory.
    func loadPlugins() {
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: pluginsDirectory, withIntermediateDirectories: true)

        // Find all .bundle files
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: pluginsDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return }

        let bundles = contents.filter { $0.pathExtension == "bundle" }

        for bundleURL in bundles {
            loadPlugin(at: bundleURL)
        }
    }

    /// Unloads all plugins.
    func unloadAllPlugins() {
        for (_, plugin) in pluginInstances {
            plugin.pluginWillUnload()
        }
        pluginInstances.removeAll()
        loadedBundles.removeAll()
        loadedPlugins.removeAll()
    }

    /// Notifies all plugins of a permission scan.
    func notifyPermissionsScan(_ permissions: [[String: Any]]) {
        for (_, plugin) in pluginInstances {
            plugin.didScanPermissions?(permissions)
        }
    }

    /// Notifies all plugins of a permission change.
    func notifyPermissionChange(service: String, client: String, oldValue: Int, newValue: Int) {
        for (_, plugin) in pluginInstances {
            plugin.permissionDidChange?(service: service, client: client, oldValue: oldValue, newValue: newValue)
        }
    }

    /// Collects custom report sections from all plugins.
    func collectReportSections(permissions: [[String: Any]]) -> [String] {
        var sections: [String] = []
        for (_, plugin) in pluginInstances {
            if let section = plugin.generateReportSection?(permissions: permissions) {
                sections.append(section)
            }
        }
        return sections
    }

    // MARK: - Private

    private func loadPlugin(at url: URL) {
        guard let bundle = Bundle(url: url) else {
            errors.append("Failed to create bundle from: \(url.lastPathComponent)")
            return
        }

        guard bundle.load() else {
            errors.append("Failed to load bundle: \(url.lastPathComponent)")
            return
        }

        guard let principalClass = bundle.principalClass as? NSObject.Type else {
            errors.append("No principal class found in: \(url.lastPathComponent)")
            return
        }

        guard let plugin = principalClass.init() as? SentryKitPlugin else {
            errors.append("Principal class does not conform to SentryKitPlugin: \(url.lastPathComponent)")
            return
        }

        let identifier = plugin.pluginIdentifier
        pluginInstances[identifier] = plugin
        loadedBundles[identifier] = bundle

        let info = PluginInfo(
            id: identifier,
            name: plugin.pluginName,
            version: plugin.pluginVersion,
            description: plugin.pluginDescription,
            bundlePath: url.path,
            isEnabled: true
        )
        loadedPlugins.append(info)

        plugin.pluginDidLoad()
        print("[PluginManager] Loaded plugin: \(plugin.pluginName) v\(plugin.pluginVersion)")
    }
}
