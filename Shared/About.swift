import Foundation

/// The wording of the About box, read from `About.json`. Compiled into the app and its UI
/// tests, and the file is bundled into both, so the tests look for exactly the text the
/// app shows.
struct AboutContent: Decodable, Sendable {
    struct LinkContent: Decodable, Sendable {
        let title: String
        let url: URL
    }

    /// The visible title of the button that opens the box.
    let buttonTitle: String
    /// What VoiceOver calls that button. It starts with `buttonTitle`'s words.
    let buttonLabel: String
    /// "{version}" and "{build}" stand for the two version numbers in the bundle.
    let versionFormat: String
    let credit: String
    let creditLink: LinkContent
    let licenseSummary: String
    /// The control that shows and hides the license text.
    let licenseTitle: String
    let sourceLink: LinkContent
    let history: String
    let doneTitle: String

    private static let resourceName = "About"
    private static let resourceExtension = "json"
    private static let versionPlaceholder = "{version}"
    private static let buildPlaceholder = "{build}"

    static func load(from bundle: Bundle) throws -> AboutContent {
        guard
            let url = bundle.url(
                forResource: resourceName, withExtension: resourceExtension)
        else {
            throw AboutResourceError.missingResource("\(resourceName).\(resourceExtension)")
        }
        return try JSONDecoder().decode(AboutContent.self, from: Data(contentsOf: url))
    }

    /// "Version 1.0 (6)", from the marketing version and the build number.
    func versionText(shortVersion: String, build: String) -> String {
        versionFormat
            .replacingOccurrences(of: Self.versionPlaceholder, with: shortVersion)
            .replacingOccurrences(of: Self.buildPlaceholder, with: build)
    }

    /// The version line for `bundle`, from its `CFBundleShortVersionString` and
    /// `CFBundleVersion`.
    func versionText(of bundle: Bundle) throws -> String {
        func value(_ key: String) throws -> String {
            guard let value = bundle.object(forInfoDictionaryKey: key) as? String else {
                throw AboutResourceError.missingInfoKey(key)
            }
            return value
        }
        return versionText(
            shortVersion: try value("CFBundleShortVersionString"),
            build: try value("CFBundleVersion"))
    }
}

/// The license the game is published under: the repository's own LICENSE file, bundled
/// as a resource so there is one copy of it.
enum AboutLicense {
    private static let resourceName = "LICENSE"

    /// The license as it is shown: each paragraph on one line, so it wraps to the width of
    /// the screen instead of at the file's 80 columns, and paragraphs a blank line apart.
    static func text(from bundle: Bundle) throws -> String {
        guard let url = bundle.url(forResource: resourceName, withExtension: nil) else {
            throw AboutResourceError.missingResource(resourceName)
        }
        return reflowed(try String(contentsOf: url, encoding: .utf8))
    }

    /// Joins the lines of each paragraph with spaces. Paragraphs are split at blank lines,
    /// counting a line of only spaces or tabs as blank, with any line ending (LF, CRLF or
    /// CR); the result separates them with one empty line.
    static func reflowed(_ text: String) -> String {
        var paragraphs: [[String]] = [[]]
        // A Character is a whole CRLF, so each kind of line ending splits exactly once.
        for line in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            let words = line.trimmingCharacters(in: .whitespaces)
            if !words.isEmpty {
                paragraphs[paragraphs.count - 1].append(words)
            } else if !(paragraphs.last ?? []).isEmpty {
                paragraphs.append([])
            }
        }
        return paragraphs
            .filter { !$0.isEmpty }
            .map { $0.joined(separator: " ") }
            .joined(separator: "\n\n")
    }
}

enum AboutResourceError: Error, Equatable {
    case missingResource(String)
    case missingInfoKey(String)
}

/// Everything the About box shows, loaded from one bundle: its wording, the version line
/// and the license.
struct AboutDetails: Sendable {
    let content: AboutContent
    let version: String
    let license: String

    static func load(from bundle: Bundle) throws -> AboutDetails {
        let content = try AboutContent.load(from: bundle)
        return AboutDetails(
            content: content,
            version: try content.versionText(of: bundle),
            license: try AboutLicense.text(from: bundle))
    }
}
