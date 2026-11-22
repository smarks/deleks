import SwiftUI

extension AboutDetails {
    /// The app's own, read from its bundle once. A missing or malformed resource is a
    /// build mistake, not something a player can cause; `AboutTests` loads the same
    /// bundle so a broken one fails the tests long before it could reach a player.
    static let app: AboutDetails = {
        do {
            return try AboutDetails.load(from: .main)
        } catch {
            fatalError("The About box's resources did not load: \(error)")
        }
    }()
}

/// Who made the game, its version, license, source and history. Stays until the player
/// taps Done (or makes VoiceOver's escape gesture); it never dismisses itself.
struct AboutBox: View {
    let details: AboutDetails
    let onDone: () -> Void
    @Environment(\.theme) private var theme
    @State private var showsLicense = false
    @AccessibilityFocusState private var headingHasFocus: Bool
    /// The box is no wider than this on a large screen, in either look.
    private static let maximumWidth: CGFloat = 460

    var body: some View {
        let content = details.content
        theme.aboutBox(
            heading: AnyView(
                Text(verbatim: DisplayText.gameTitle)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($headingHasFocus)),
            version: AnyView(
                Text(verbatim: details.version)
                    .accessibilityIdentifier(AccessibilityID.aboutVersion)),
            sections: [
                AnyView(
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: content.credit)
                            .accessibilityIdentifier(AccessibilityID.aboutCredit)
                        link(content.creditLink, identifier: AccessibilityID.aboutCreditLink)
                    }),
                AnyView(
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: content.licenseSummary)
                            .accessibilityIdentifier(AccessibilityID.aboutLicenseSummary)
                        theme.aboutDisclosure(
                            label: AnyView(
                                Text(verbatim: content.licenseTitle)
                                    .accessibilityIdentifier(AccessibilityID.aboutLicense)),
                            isExpanded: $showsLicense,
                            content: AnyView(
                                Text(verbatim: details.license)
                                    .accessibilityIdentifier(AccessibilityID.aboutLicenseText)))
                    }),
                AnyView(link(content.sourceLink, identifier: AccessibilityID.aboutSourceLink)),
                AnyView(
                    Text(verbatim: content.history)
                        .accessibilityIdentifier(AccessibilityID.aboutHistory)),
            ],
            doneButton: AnyView(
                theme.aboutDoneButton(title: content.doneTitle, action: onDone)
                    // Return closes it, as it closed a classic dialog.
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier(AccessibilityID.aboutDone))
        )
        .frame(maxWidth: Self.maximumWidth)
        .padding(16)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier(AccessibilityID.aboutBox)
        .accessibilityAction(.escape, onDone)
        .onAppear { headingHasFocus = true }
    }

    private func link(_ link: AboutContent.LinkContent, identifier: String) -> some View {
        theme.aboutLink(title: link.title, destination: link.url)
            .accessibilityIdentifier(identifier)
    }
}
