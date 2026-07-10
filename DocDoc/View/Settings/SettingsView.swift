//
//  SettingsView.swift
//  DocDoc
//

import SwiftUI

struct SettingsView: View {
    @State private var autoImprove = true
    @State private var autoCrop = true
    @State private var saveOriginals = false
    @State private var pdfQuality = "Высокое"

    private let qualityOptions = ["Высокое", "Среднее", "Низкое"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Настройки")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.horizontal, 20)

                    SettingsGroup(title: "Сканирование") {
                        SettingsToggleRow(title: "Авто-улучшение после съёмки", isOn: $autoImprove)
                        SettingsDivider()
                        SettingsToggleRow(title: "Авто-обрезка границ", isOn: $autoCrop)
                        SettingsDivider()
                        SettingsPickerRow(title: "Качество PDF по умолчанию", selection: $pdfQuality, options: qualityOptions)
                    }

                    SettingsGroup(title: "Хранение") {
                        SettingsToggleRow(title: "Сохранять оригиналы", isOn: $saveOriginals)
                        SettingsDivider()
                        SettingsInfoRow(title: "Использовано", value: "24 MB / 1 GB")
                    }

                    SettingsGroup(title: "О приложении") {
                        SettingsInfoRow(title: "Версия", value: "1.0.0 (прототип)")
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(DocDocTheme.background)
            .navigationBarHidden(true)
        }
    }
}

private struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(DocDocTheme.textSecondary)
                .padding(.horizontal, 24)

            VStack(spacing: 0) {
                content
            }
            .docDocCard()
            .padding(.horizontal, 20)
        }
    }
}

private struct SettingsToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .font(.subheadline)
            .tint(DocDocTheme.accent)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
    }
}

private struct SettingsPickerRow: View {
    let title: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .labelsHidden()
            .tint(DocDocTheme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

private struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(DocDocTheme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 16)
    }
}

#Preview {
    SettingsView()
}
