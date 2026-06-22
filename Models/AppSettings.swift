import Foundation
import SwiftUI

/// User-facing application settings persisted in UserDefaults.
///
/// Uses `@Observable` with manual UserDefaults backing so it can be
/// used as a shared singleton outside of SwiftUI View context.
@MainActor
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // MARK: - API

    var apiEndpoint: String {
        get { defaults.string(forKey: "apiEndpoint") ?? "https://integrate.api.nvidia.com/v1" }
        set { defaults.set(newValue, forKey: "apiEndpoint") }
    }

    var defaultModelId: String {
        get { defaults.string(forKey: "defaultModelId") ?? "nvidia/llama-3.1-nemotron-70b-instruct" }
        set { defaults.set(newValue, forKey: "defaultModelId") }
    }

    var defaultSystemPrompt: String {
        get { defaults.string(forKey: "defaultSystemPrompt") ?? "" }
        set { defaults.set(newValue, forKey: "defaultSystemPrompt") }
    }

    // MARK: - Sampling Defaults

    var defaultTemperature: Double {
        get { defaults.object(forKey: "defaultTemperature") as? Double ?? 0.7 }
        set { defaults.set(newValue, forKey: "defaultTemperature") }
    }

    var defaultTopP: Double {
        get { defaults.object(forKey: "defaultTopP") as? Double ?? 0.95 }
        set { defaults.set(newValue, forKey: "defaultTopP") }
    }

    var defaultMaxTokens: Int {
        get { defaults.object(forKey: "defaultMaxTokens") as? Int ?? 1024 }
        set { defaults.set(newValue, forKey: "defaultMaxTokens") }
    }

    // MARK: - Google Search

    var googleSearchEnabled: Bool {
        get { defaults.bool(forKey: "googleSearchEnabled") }
        set { defaults.set(newValue, forKey: "googleSearchEnabled") }
    }

    var googleSearchMaxResults: Int {
        get { defaults.object(forKey: "googleSearchMaxResults") as? Int ?? 5 }
        set { defaults.set(newValue, forKey: "googleSearchMaxResults") }
    }

    // MARK: - Behavior

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: "launchAtLogin") }
        set { defaults.set(newValue, forKey: "launchAtLogin") }
    }

    var globalHotkey: String {
        get { defaults.string(forKey: "globalHotkey") ?? "cmd+shift+n" }
        set { defaults.set(newValue, forKey: "globalHotkey") }
    }

    var popoverStaysOpen: Bool {
        get { defaults.bool(forKey: "popoverStaysOpen") }
        set { defaults.set(newValue, forKey: "popoverStaysOpen") }
    }

    // MARK: - History

    var autoSaveHistory: Bool {
        get { defaults.object(forKey: "autoSaveHistory") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "autoSaveHistory") }
    }

    var maxHistoryDays: Int {
        get { defaults.object(forKey: "maxHistoryDays") as? Int ?? 90 }
        set { defaults.set(newValue, forKey: "maxHistoryDays") }
    }

    // MARK: - Metrics

    var metricsRetentionDays: Int {
        get { defaults.object(forKey: "metricsRetentionDays") as? Int ?? 365 }
        set { defaults.set(newValue, forKey: "metricsRetentionDays") }
    }

    // MARK: - Appearance

    var appearance: String {
        get { defaults.string(forKey: "appearance") ?? "system" }
        set { defaults.set(newValue, forKey: "appearance") }
    }

    // MARK: - Network

    /// Request timeout in seconds (time without data before giving up).
    var requestTimeout: Int {
        get { defaults.object(forKey: "requestTimeout") as? Int ?? 30 }
        set { defaults.set(newValue, forKey: "requestTimeout") }
    }

    /// Resource timeout in seconds (total time including retries).
    var resourceTimeout: Int {
        get { defaults.object(forKey: "resourceTimeout") as? Int ?? 120 }
        set { defaults.set(newValue, forKey: "resourceTimeout") }
    }

    /// Maximum retry attempts for transient errors (429, 5xx, network).
    var maxRetries: Int {
        get { defaults.object(forKey: "maxRetries") as? Int ?? 3 }
        set { defaults.set(newValue, forKey: "maxRetries") }
    }

    private init() {}
}
