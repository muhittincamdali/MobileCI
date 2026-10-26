import Foundation
@testable import MobileCIKit
import Testing

struct VersionNumberTests {
    @Test(arguments: [("2.4.1", MarketingVersion.self), ("1", MarketingVersion.self), ("1.2.3-beta.1", MarketingVersion.self)])
    func readsVersions(text: String, _: MarketingVersion.Type) throws {
        #expect(try MarketingVersion(text).description == text)
    }

    @Test(arguments: ["", "1.", ".1", "1.2.3.4", "v1.2", "1.2.x", "+1.2", "1.-2", "1.2.3-", "1.2.3-be ta", "١.٢.٣", "1e3"])
    func refusesNonVersions(text: String) {
        #expect(throws: VersionError.self) { try MarketingVersion(text) }
    }

    @Test func refusesComponentsThatWouldOverflow() {
        #expect(throws: VersionError.self) { try MarketingVersion("1.99999999999999999999.0") }
        #expect(throws: VersionError.self) { try MarketingVersion("1000000000.0.0") }
        #expect(throws: VersionError.versionPartTooLarge("999999999.0.0", limit: 999_999_999)) {
            try MarketingVersion("999999999.0.0").bumped(.major)
        }
        let message = VersionError.versionPartTooLarge("1.999999999", limit: MarketingVersion.maximumComponent).description
        #expect(message == "1.999999999 cannot be bumped: each part of a version is at most 999999999.")
        #expect(!message.contains("Google Play"))
    }

    @Test func bumps() throws {
        let version = try MarketingVersion("2.4.1")
        #expect(try version.bumped(.major).description == "3.0.0")
        #expect(try version.bumped(.minor).description == "2.5.0")
        #expect(try version.bumped(.patch).description == "2.4.2")
        #expect(try MarketingVersion("1.2").bumped(.patch).description == "1.2.1")
        #expect(try MarketingVersion("1").bumped(.minor).description == "1.1")
        #expect(try MarketingVersion("2.0.0-rc.1").bumped(.patch).description == "2.0.1")
    }

    @Test func ordering() throws {
        #expect(try MarketingVersion("1.10") > MarketingVersion("1.9.9"))
        #expect(try MarketingVersion("1.2") == MarketingVersion("1.2"))
        #expect(try !(MarketingVersion("1.2") < MarketingVersion("1.2.0")))
        #expect(try MarketingVersion("2.0.0-beta") < MarketingVersion("2.0.0"))
    }

    @Test func buildNumbersStayInsideTheGooglePlayLimit() throws {
        #expect(try BuildNumber("42").value == 42)
        #expect(try BuildNumber("\"7\"").value == 7)
        #expect(try BuildNumber("2100000000").value == BuildNumber.maximum)
        #expect(throws: VersionError.tooLarge("2100000001", limit: BuildNumber.maximum)) { try BuildNumber("2100000001") }
        #expect(throws: VersionError.self) { try BuildNumber("99999999999999999999999") }
        #expect(throws: VersionError.self) { try BuildNumber("-1") }
        #expect(throws: VersionError.self) { try BuildNumber("1.2") }
        #expect(throws: VersionError.self) { try BuildNumber("") }
        #expect(throws: VersionError.self) { try BuildNumber(value: Int.max) }
        #expect(throws: VersionError.self) { try BuildNumber("2100000000").incremented() }
        #expect(try BuildNumber("9").incremented().value == 10)
    }

    @Test func decimalParsingNeverOverflows() {
        #expect(DecimalNumber.parse("000123", maximum: 1_000) == 123)
        #expect(DecimalNumber.parse("1001", maximum: 1_000) == nil)
        #expect(DecimalNumber.parse(Substring(String(repeating: "9", count: 19)), maximum: Int.max) == nil)
        #expect(DecimalNumber.parse("+1", maximum: 10) == nil)
        #expect(DecimalNumber.parse("", maximum: 10) == nil)
    }
}

struct JSONValueLocatorTests {
    let text = """
    {"name": "app", "version": "1.2.0", "files": ["version"],
     "expo": {"plugins": [{"version": "x"}], "version": "3.1.0",
              "ios": {"buildNumber": "12"}, "android": {"versionCode": 7}}}
    """

    func value(_ path: [String]) -> String? {
        JSONValueLocator.find(path, in: text).map { String(text[$0.range]) }
    }

    @Test func findsNestedValues() {
        #expect(value(["version"]) == "1.2.0")
        #expect(value(["expo", "version"]) == "3.1.0")
        #expect(value(["expo", "ios", "buildNumber"]) == "12")
        #expect(value(["expo", "android", "versionCode"]) == "7")
        #expect(JSONValueLocator.find(["expo", "android", "versionCode"], in: text)?.isString == false)
    }

    @Test func doesNotMatchInsideArraysOrMissingKeys() {
        #expect(value(["expo", "plugins", "version"]) == nil)
        #expect(value(["expo", "missing"]) == nil)
        #expect(value(["name", "version"]) == nil)
    }

    @Test func escapedStringsAndDeepNestingGiveNil() {
        #expect(JSONValueLocator.find(["version"], in: #"{"version": "1.2\/0"}"#) == nil)
        let deep = String(repeating: "{\"a\":", count: 100) + "1" + String(repeating: "}", count: 100)
        #expect(JSONValueLocator.find(Array(repeating: "a", count: 100), in: deep) == nil)
    }
}

struct VersionFileTests {
    @Test func pubspecVersionAndBuild() throws {
        let folder = try TemporaryFolder()
        let url = try folder.write("pubspec.yaml", "name: shop\n# version: 0.0.1\nversion: 1.2.3+45 # release\n")
        let file = try #require(VersionFile(url: url, path: "pubspec.yaml", format: .pubspec))
        #expect(file.versions == ["1.2.3"] && file.buildNumbers == ["45"])
        #expect(file.updatedText(version: "1.3.0", build: "46") == "name: shop\n# version: 0.0.1\nversion: 1.3.0+46 # release\n")
    }

    @Test func pubspecWithoutBuildGetsOne() throws {
        let folder = try TemporaryFolder()
        let url = try folder.write("pubspec.yaml", "version: '2.0.0'\n")
        let file = try #require(VersionFile(url: url, path: "pubspec.yaml", format: .pubspec))
        #expect(file.buildNumbers.isEmpty)
        #expect(file.updatedText(version: nil, build: "1") == "version: '2.0.0+1'\n")
        #expect(file.updatedText(version: "2.0.1", build: nil) == "version: '2.0.1'\n")
    }

    @Test func xcodeProjectEveryConfiguration() throws {
        let folder = try TemporaryFolder()
        let text = Fixture.projectFile(marketing: "\"1.4\"", build: "9") + "\n\t\tMARKETING_VERSION = \"$(inherited)\";\n"
        let url = try folder.write("App.xcodeproj/project.pbxproj", text)
        let file = try #require(VersionFile(url: url, path: "p", format: .xcodeProject))
        #expect(file.versions == ["1.4", "1.4"] && file.buildNumbers == ["9", "9"])
        let updated = file.updatedText(version: "1.5", build: "10")
        #expect(updated.components(separatedBy: "MARKETING_VERSION = \"1.5\";").count == 3)
        #expect(updated.components(separatedBy: "CURRENT_PROJECT_VERSION = 10;").count == 3)
        #expect(updated.contains("MARKETING_VERSION = \"$(inherited)\";"))
    }

    @Test func gradleLiteralsOnly() throws {
        let folder = try TemporaryFolder()
        let text = """
        android {
            defaultConfig {
                versionCode 7
                versionName "1.0"
            }
            flavorDimensions "x"
            productFlavors { beta { versionCode = 70 } }
            other { versionCode flutterVersionCode.toInteger() }
        }
        """
        let url = try folder.write("build.gradle", text)
        let file = try #require(VersionFile(url: url, path: "g", format: .gradle))
        #expect(file.versions == ["1.0"] && file.buildNumbers == ["7"])
        let updated = file.updatedText(version: "1.1", build: "8")
        #expect(updated.contains("versionCode 8") && updated.contains("versionName \"1.1\""))
        #expect(updated.contains("versionCode flutterVersionCode.toInteger()"))
    }

    @Test func expoAppJSONKeepsFormatting() throws {
        let folder = try TemporaryFolder()
        let text = "{\n  \"expo\": {\n    \"name\": \"Shop\",\n    \"version\": \"1.0.0\",\n    \"android\": { \"versionCode\": 3 }\n  }\n}\n"
        let url = try folder.write("app.json", text)
        let file = try #require(VersionFile(url: url, path: "app.json", format: .expo))
        #expect(file.updatedText(version: "1.1.0", build: "4")
            == "{\n  \"expo\": {\n    \"name\": \"Shop\",\n    \"version\": \"1.1.0\",\n    \"android\": { \"versionCode\": 4 }\n  }\n}\n")
    }

    @Test func filesWithoutVersionsAreSkipped() throws {
        let folder = try TemporaryFolder()
        let url = try folder.write("package.json", "{\"name\": \"x\"}")
        #expect(VersionFile(url: url, path: "package.json", format: .packageJSON) == nil)
        let broken = try folder.write("app.json", "{\"expo\": {\"version\": \"1.0\"")
        #expect(VersionFile(url: broken, path: "app.json", format: .expo) == nil)
    }
}

struct VersionManagerTests {
    func reactNativeApp() throws -> (TemporaryFolder, [VersionFile]) {
        let folder = try TemporaryFolder()
        try folder.write("package.json", "{\"name\": \"shop\", \"version\": \"0.0.1\", \"dependencies\": {\"react-native\": \"0.87.0\"}}")
        try folder.write("package-lock.json", "{}")
        try folder.write("ios/Shop.xcodeproj/project.pbxproj", Fixture.projectFile(marketing: "1.4.0", build: "12"))
        try folder.write("ios/Shop.xcodeproj/xcshareddata/xcschemes/Shop.xcscheme", Fixture.scheme(withTests: false))
        try folder.write("android/app/build.gradle", "defaultConfig {\n    versionCode 11\n    versionName \"1.3.9\"\n}\n")
        let project = try #require(ProjectDetector().detect(in: folder.url).projects.first)
        return (folder, VersionManager().files(for: project, root: folder.url))
    }

    @Test func findsEveryFileAndTheHighestValues() throws {
        let (_, files) = try reactNativeApp()
        #expect(files.map(\.path) == ["package.json", "ios/Shop.xcodeproj/project.pbxproj", "android/app/build.gradle"])
        let current = VersionManager().current(in: files)
        #expect(current.version?.description == "1.4.0" && current.build?.value == 12)
    }

    @Test func bumpWritesTheSameValuesEverywhere() throws {
        let (folder, files) = try reactNativeApp()
        let plan = try VersionManager().plan(.bump(.minor, build: true), files: files)
        #expect(plan.version?.description == "1.5.0" && plan.build?.value == 13)
        try plan.apply()
        #expect(try folder.read("package.json").contains("\"version\": \"1.5.0\""))
        #expect(try folder.read("ios/Shop.xcodeproj/project.pbxproj").components(separatedBy: "MARKETING_VERSION = 1.5.0;").count == 3)
        #expect(try folder.read("android/app/build.gradle") == "defaultConfig {\n    versionCode 13\n    versionName \"1.5.0\"\n}\n")
    }

    @Test func buildOnlyChangesLeaveVersionsAlone() throws {
        let (folder, files) = try reactNativeApp()
        try VersionManager().plan(.setBuild(try BuildNumber("100")), files: files).apply()
        #expect(try folder.read("android/app/build.gradle").contains("versionCode 100"))
        #expect(try folder.read("android/app/build.gradle").contains("versionName \"1.3.9\""))
    }

    @Test func nextBuildAtTheLimitFails() throws {
        let folder = try TemporaryFolder()
        let url = try folder.write("pubspec.yaml", "version: 1.0.0+2100000000\n")
        let file = try #require(VersionFile(url: url, path: "pubspec.yaml", format: .pubspec))
        #expect(throws: VersionError.self) { try VersionManager().plan(.nextBuild, files: [file]) }
    }

    /// `1.2.3` is a valid Apple build string but not a number this tool can increment; counting
    /// from 1 would write a lower build into every file.
    @Test func unreadableBuildNumbersAreNotResetToOne() throws {
        let folder = try TemporaryFolder()
        let url = try folder.write("App.xcodeproj/project.pbxproj", Fixture.projectFile(marketing: "2.0", build: "1.2.3"))
        let file = try #require(VersionFile(url: url, path: "p", format: .xcodeProject))
        #expect(file.buildNumbers == ["1.2.3", "1.2.3"])
        #expect(throws: VersionError.unreadableBuildNumber("1.2.3")) { try VersionManager().plan(.nextBuild, files: [file]) }
        #expect(throws: VersionError.unreadableBuildNumber("1.2.3")) {
            try VersionManager().plan(.bump(.patch, build: true), files: [file])
        }
        #expect(try VersionManager().plan(.bump(.patch, build: false), files: [file]).version?.description == "2.0.1")
        #expect(try VersionManager().plan(.setBuild(BuildNumber("5")), files: [file]).build?.value == 5)
    }

    @Test func swiftPackagesHaveNothingToVersion() {
        #expect(throws: VersionError.self) { try VersionManager().plan(.nextBuild, files: []) }
    }
}
