import Foundation
import Testing

@testable import deleks

/// The About box's resources, loaded from the app's own bundle exactly as the box loads
/// them, so a file left out of the build or a typo in About.json fails here.
@Suite("About")
struct AboutTests {
    @Test func theWordingDecodesFromTheBundledFile() throws {
        let content = try AboutContent.load(from: .main)
        let shownText = [
            content.buttonTitle, content.buttonLabel, content.versionFormat, content.credit,
            content.creditLink.title, content.licenseSummary, content.licenseTitle,
            content.sourceLink.title, content.history, content.doneTitle,
        ]
        #expect(shownText.allSatisfy { !$0.isEmpty })
        #expect(content.creditLink.url == URL(string: "https://origamisoftware.com"))
        #expect(content.sourceLink.url == URL(string: "https://github.com/smarks/deleks"))
        // VoiceOver's name for the button includes the words the button shows.
        let shownWords = content.buttonTitle.trimmingCharacters(in: .punctuationCharacters)
        #expect(content.buttonLabel.hasPrefix(shownWords))
    }

    /// The game is sold, so the box's own wording never calls it free. (The MIT License's
    /// own text says "free of charge" about the source; that is the license, not the box.)
    @Test func theWordingNeverCallsTheGameFree() throws {
        let content = try AboutContent.load(from: .main)
        let shownText = [
            content.buttonTitle, content.buttonLabel, content.credit, content.creditLink.title,
            content.licenseSummary, content.licenseTitle, content.sourceLink.title,
            content.history, content.doneTitle,
        ]
        let free = /\bfree\b/.ignoresCase()
        #expect(shownText.filter { $0.contains(free) } == [])
    }

    @Test func aFileMissingAFieldIsRejected() {
        let incomplete = Data(#"{"buttonTitle": "About…"}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(AboutContent.self, from: incomplete)
        }
    }

    @Test func aBundleWithoutTheFilesSaysWhichIsMissing() {
        let testBundle = Bundle(for: BundleMarker.self)
        #expect(throws: AboutResourceError.missingResource("About.json")) {
            try AboutContent.load(from: testBundle)
        }
        #expect(throws: AboutResourceError.missingResource("LICENSE")) {
            try AboutLicense.text(from: testBundle)
        }
    }

    @Test func theVersionLineNamesTheVersionAndTheBuild() throws {
        let content = try AboutContent.load(from: .main)
        #expect(content.versionText(shortVersion: "1.0", build: "6") == "Version 1.0 (6)")
    }

    @Test func theVersionLineIsReadFromTheBundle() throws {
        let content = try AboutContent.load(from: .main)
        let info = try #require(Bundle.main.infoDictionary)
        let shortVersion = try #require(info["CFBundleShortVersionString"] as? String)
        let build = try #require(info["CFBundleVersion"] as? String)
        #expect(
            try content.versionText(of: .main)
                == content.versionText(shortVersion: shortVersion, build: build))
    }

    @Test func theLicenseIsTheMITLicenseWithItsCopyrightLine() throws {
        let license = try AboutLicense.text(from: .main)
        #expect(license.contains("MIT License"))
        #expect(license.contains("Copyright (c) 2026 Spencer Marks"))
        #expect(license.contains("Permission is hereby granted, free of charge"))
    }

    /// The file wraps at 80 columns; the box shows each of its five paragraphs as one
    /// line, so it wraps to the screen instead, with an empty line between paragraphs.
    @Test func theLicenseIsReflowedIntoItsFiveParagraphs() throws {
        let paragraphs = try AboutLicense.text(from: .main).components(separatedBy: "\n\n")
        #expect(
            paragraphs == [
                "MIT License",
                "Copyright (c) 2026 Spencer Marks",
                "Permission is hereby granted, free of charge, to any person obtaining a copy "
                    + "of this software and associated documentation files (the \"Software\"), "
                    + "to deal in the Software without restriction, including without "
                    + "limitation the rights to use, copy, modify, merge, publish, distribute, "
                    + "sublicense, and/or sell copies of the Software, and to permit persons to "
                    + "whom the Software is furnished to do so, subject to the following "
                    + "conditions:",
                "The above copyright notice and this permission notice shall be included in "
                    + "all copies or substantial portions of the Software.",
                "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR "
                    + "IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF "
                    + "MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. "
                    + "IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY "
                    + "CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, "
                    + "TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE "
                    + "SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.",
            ])
    }

    @Test func reflowingJoinsLinesAndKeepsParagraphsApart() {
        #expect(AboutLicense.reflowed("One\ntwo\n\nThree\n") == "One two\n\nThree")
        // Leading, trailing and repeated blank lines leave no empty paragraph behind.
        #expect(AboutLicense.reflowed("\n\nOne\n\n\n\nTwo\n\n") == "One\n\nTwo")
    }

    /// A LICENSE saved on Windows still reflows into its paragraphs.
    @Test func reflowingHandlesCRLFAndCRLineEndings() {
        #expect(AboutLicense.reflowed("One\r\ntwo\r\n\r\nThree\r\n") == "One two\n\nThree")
        #expect(AboutLicense.reflowed("One\rtwo\r\rThree\r") == "One two\n\nThree")
    }

    /// A line of only spaces or tabs between paragraphs still separates them.
    @Test func aWhitespaceOnlyLineSeparatesParagraphs() {
        #expect(AboutLicense.reflowed("One\ntwo\n  \t \nThree") == "One two\n\nThree")
    }

    @Test func theAppLoadsEverythingTheBoxShows() throws {
        let details = try AboutDetails.load(from: .main)
        #expect(details.version == (try details.content.versionText(of: .main)))
        #expect(details.license == (try AboutLicense.text(from: .main)))
    }
}

/// Finds the unit-test bundle, which carries neither About.json nor LICENSE.
private final class BundleMarker {}
