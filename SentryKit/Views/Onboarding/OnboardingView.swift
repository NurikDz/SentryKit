// OnboardingView.swift
// SentryKit
//
// First-launch onboarding experience explaining what SentryKit does
// and guiding the user to grant Full Disk Access.

import SwiftUI

struct OnboardingView: View {

    @Binding var isPresented: Bool
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentPage: Int = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "lock.shield.fill",
            iconColor: .blue,
            title: "Welcome to SentryKit",
            subtitle: "Your macOS Privacy Permission Dashboard",
            description: "SentryKit helps you understand and manage the privacy permissions (TCC) that apps request on your Mac. No more digging through System Settings or wondering which apps can see your screen.",
            bulletPoints: [
                "See all app permissions in one place",
                "Get notified when permissions change",
                "Quick-reset permissions that keep re-prompting",
                "Export security audit reports"
            ]
        ),
        OnboardingPage(
            icon: "eye.trianglebadge.exclamationmark",
            iconColor: .orange,
            title: "What is TCC?",
            subtitle: "Transparency, Consent, and Control",
            description: "TCC is Apple's privacy system that controls which apps can access sensitive resources like your screen, microphone, camera, files, and more. Since macOS Mojave, every app must ask permission before accessing these resources.",
            bulletPoints: [
                "Screen Recording — for screenshot and recording tools",
                "Accessibility — for automation and window managers",
                "Full Disk Access — for backup and cleaning tools",
                "Input Monitoring — for keyboard macro tools",
                "Microphone & Camera — for video conferencing"
            ]
        ),
        OnboardingPage(
            icon: "internaldrive.fill",
            iconColor: .purple,
            title: "Full Disk Access Required",
            subtitle: "SentryKit needs permission to read the TCC database",
            description: "To show you which apps have which permissions, SentryKit needs to read the TCC database files stored on your Mac. This requires Full Disk Access — the same permission trusted tools like CleanMyMac and OnyX use.",
            bulletPoints: [
                "SentryKit only reads the TCC database (read-only)",
                "It never modifies permissions without your explicit action",
                "All data stays on your Mac — nothing is sent anywhere",
                "You can revoke this access at any time"
            ]
        ),
        OnboardingPage(
            icon: "checkmark.shield.fill",
            iconColor: .green,
            title: "You're All Set!",
            subtitle: "Grant Full Disk Access to get started",
            description: "Click the button below to open System Settings. Find SentryKit in the list and enable the toggle. Then come back here and start exploring your permissions.",
            bulletPoints: [
                "1. Click \"Open Full Disk Access Settings\"",
                "2. Find SentryKit in the list",
                "3. Enable the toggle",
                "4. Return here and click \"Get Started\""
            ]
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Content
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    onboardingPageView(page)
                        .tag(index)
                }
            }
            .tabViewStyle(.automatic)

            Divider()

            // Navigation
            HStack {
                // Page indicators
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()

                // Buttons
                if currentPage > 0 {
                    Button("Back") {
                        withAnimation { currentPage -= 1 }
                    }
                    .buttonStyle(.bordered)
                }

                if currentPage < pages.count - 1 {
                    Button("Next") {
                        withAnimation { currentPage += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Open Full Disk Access Settings") {
                        SystemSettingsService().openFullDiskAccess()
                    }
                    .buttonStyle(.bordered)

                    Button("Get Started") {
                        hasCompletedOnboarding = true
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func onboardingPageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 56))
                .foregroundColor(page.iconColor)

            Text(page.title)
                .font(.title.bold())

            Text(page.subtitle)
                .font(.title3)
                .foregroundColor(.secondary)

            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(page.bulletPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                            .padding(.top, 2)
                        Text(point)
                            .font(.callout)
                    }
                }
            }
            .padding(.horizontal, 60)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
    let bulletPoints: [String]
}
