//
//  RootView.swift
//  DocDoc
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var documentStore = DocumentStore()

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .environment(documentStore)
        .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
    }
}

#Preview {
    RootView()
}
