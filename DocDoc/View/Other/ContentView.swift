//
//  ContentView.swift
//  DocDoc
//

import SwiftUI

struct MainTabView: View {
    @Environment(DocumentStore.self) private var documentStore

    @State private var selectedTab: AppTab = .home
    @State private var showCamera = false
    @State private var pendingCapture: UIImage?
    @State private var activeScan: CapturedScan?

    var body: some View {
        TabView(selection: $selectedTab) {
            MainView(
                selectedTab: $selectedTab,
                documents: documentStore.documents,
                onScan: openCamera,
                onImagePicked: startProcessing
            )
            .tabItem {
                Label("Главная", systemImage: "house.fill")
            }
            .tag(AppTab.home)

            DocumentsView(
                documents: documentStore.documents,
                onScan: openCamera
            )
            .tabItem {
                Label("Документы", systemImage: "folder.fill")
            }
            .tag(AppTab.documents)

            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape.fill")
                }
                .tag(AppTab.settings)
        }
        .tint(DocDocTheme.accent)
        .fullScreenCover(isPresented: $showCamera, onDismiss: presentProcessingIfNeeded) {
            CameraView { image in
                pendingCapture = image
                showCamera = false
            }
        }
        .fullScreenCover(item: $activeScan) { scan in
            ScanFlowView(sourceImage: scan.image) {
                activeScan = nil
                showCamera = true
            }
        }
    }

    private func openCamera() {
        showCamera = true
    }

    private func startProcessing(_ image: UIImage) {
        activeScan = CapturedScan(image: image)
    }

    private func presentProcessingIfNeeded() {
        guard let pendingCapture else { return }
        activeScan = CapturedScan(image: pendingCapture)
        self.pendingCapture = nil
    }
}

private struct CapturedScan: Identifiable {
    let id = UUID()
    let image: UIImage
}

#Preview {
    MainTabView()
        .environment(DocumentStore())
}
