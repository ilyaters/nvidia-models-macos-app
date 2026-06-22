import XCTest
@testable import NvidiaLLM

@MainActor
final class HealthCheckServiceTests: XCTestCase {
    func testNoApiKeyReturnsNoApiKeyStatus() async {
        let service = HealthCheckService()
        await service.check(
            model: "nvidia/test-model",
            endpoint: "https://test.example.com/v1",
            apiKey: ""
        )
        XCTAssertEqual(service.status(for: "nvidia/test-model"), .noApiKey)
    }

    func testInvalidURLReturnsUnavailable() async {
        let service = HealthCheckService()
        await service.check(
            model: "nvidia/test-model",
            endpoint: "not a url",
            apiKey: "test-key"
        )
        let status = service.status(for: "nvidia/test-model")
        if case .unavailable = status {
            // expected
        } else {
            XCTFail("Expected unavailable, got \(status)")
        }
    }

    func testNetworkErrorReturnsUnavailable() async {
        let service = HealthCheckService()
        await service.check(
            model: "nvidia/test-model",
            endpoint: "https://invalid.example.com/v1",
            apiKey: "test-key"
        )
        let status = service.status(for: "nvidia/test-model")
        if case .unavailable = status {
            // expected — network error
        } else {
            XCTFail("Expected unavailable, got \(status)")
        }
    }

    func testUnknownStatusForUncheckedModel() {
        let service = HealthCheckService()
        XCTAssertEqual(service.status(for: "unchecked-model"), .unknown)
    }

    func testClearRemovesAllStatuses() async {
        let service = HealthCheckService()
        await service.check(
            model: "nvidia/test-model",
            endpoint: "https://test.example.com/v1",
            apiKey: ""
        )
        XCTAssertNotEqual(service.status(for: "nvidia/test-model"), .unknown)

        service.clear()

        XCTAssertEqual(service.status(for: "nvidia/test-model"), .unknown)
    }

    func testModelHealthStatusIcons() {
        XCTAssertEqual(ModelHealthStatus.unknown.icon, "questionmark.circle")
        XCTAssertEqual(ModelHealthStatus.checking.icon, "arrow.triangle.2.circlepath")
        XCTAssertEqual(ModelHealthStatus.available.icon, "checkmark.circle.fill")
        XCTAssertEqual(ModelHealthStatus.noApiKey.icon, "lock.circle")
    }

    func testModelHealthStatusLabels() {
        XCTAssertEqual(ModelHealthStatus.unknown.label, "Unknown")
        XCTAssertEqual(ModelHealthStatus.checking.label, "Checking…")
        XCTAssertEqual(ModelHealthStatus.available.label, "Available")
        XCTAssertEqual(ModelHealthStatus.noApiKey.label, "No API key")
    }
}

final class ThemeManagerTests: XCTestCase {
    @MainActor
    func testCycleChangesAppearance() {
        let theme = ThemeManager.shared
        let original = theme.appearance

        theme.cycle()
        XCTAssertNotEqual(theme.appearance, original)

        // Cycle through all three modes.
        theme.cycle()
        theme.cycle()

        // After 3 cycles we should be back to the original.
        XCTAssertEqual(theme.appearance, original)
    }

    func testAppearanceModeColorScheme() {
        XCTAssertNil(AppearanceMode.system.colorScheme)
        XCTAssertEqual(AppearanceMode.light.colorScheme, .light)
        XCTAssertEqual(AppearanceMode.dark.colorScheme, .dark)
    }

    func testAppearanceModeIcons() {
        XCTAssertEqual(AppearanceMode.system.icon, "circle.lefthalf.filled")
        XCTAssertEqual(AppearanceMode.light.icon, "sun.max.fill")
        XCTAssertEqual(AppearanceMode.dark.icon, "moon.stars.fill")
    }
}
