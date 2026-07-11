import PhotosUI
import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var store: ScanHistoryStore
    @AppStorage("clearhalal.firstName") private var firstName = ""
    private let config = ScannerCoachAppConfig.clearHalal
    private let recognizer = LabelTextRecognizer()
    @State private var input = ""
    @State private var showManualEntry = false
    @State private var showCamera = false
    @State private var showResult = false
    @State private var isReadingLabel = false
    @State private var scanError: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var manualEntryDetent: PresentationDetent = .medium

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ClearHalalBrandHeader()

                    VStack(alignment: .leading, spacing: 8) {
                        Text(greeting)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(ClearHalalTheme.secondaryText)
                        Text("Peace of mind in\nevery ingredient.")
                            .font(ClearHalalTheme.display(34, weight: .semibold))
                            .foregroundStyle(ClearHalalTheme.primaryText)
                    }

                    Button {
                        startCameraScan()
                    } label: {
                        ZStack(alignment: .bottomTrailing) {
                            VStack(alignment: .leading, spacing: 18) {
                                Image(systemName: "viewfinder")
                                    .font(.system(size: 28, weight: .semibold))
                                Spacer()
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(config.primaryActionTitle)
                                        .font(.title2.bold())
                                    Text(config.primaryActionSubtitle)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color(hex: 0xEAF2EE))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Circle()
                                .fill(.white)
                                .frame(width: 42, height: 42)
                                .overlay {
                                    Image(systemName: "chevron.right")
                                        .font(.headline.weight(.semibold))
                                        .foregroundStyle(ClearHalalTheme.deepForest)
                                }
                        }
                        .padding(26)
                        .frame(maxWidth: .infinity, minHeight: 188)
                        .background(
                            LinearGradient(
                                colors: [ClearHalalTheme.deepForest, ClearHalalTheme.pantryGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: ClearHalalTheme.deepForest.opacity(0.18), radius: 18, y: 10)
                    }
                    .disabled(isReadingLabel)

                    if isReadingLabel {
                        ProcessingLabelCard()
                    }

                    if let scanError {
                        ErrorLabelCard(message: scanError)
                    }

                    HStack(spacing: 18) {
                        SecondaryInputCard(icon: "pencil", title: "Type", subtitle: "Ingredients") {
                            showManualEntry = true
                        }
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            SecondaryInputCardContent(icon: "photo.on.rectangle", title: "Upload", subtitle: "Photo label")
                        }
                        .buttonStyle(.plain)
                    }

                    ClearChoicesWeeklyCard(progress: store.progress)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Recent checks", subtitle: "Your latest grocery decisions")

                        ForEach(store.history.prefix(2)) { result in
                            NavigationLink(value: result) {
                                HistoryRow(result: result)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(28)
                .padding(.bottom, ClearHalalTheme.tabBarScrollClearance)
            }
            .background(ClearHalalTheme.background.ignoresSafeArea())
            .navigationDestination(for: ScanResult.self) { result in
                ResultView(result: result)
            }
            .sheet(isPresented: $showManualEntry) {
                ManualEntryView(isCompactDetent: manualEntryDetent == .medium) { text in
                    store.check(text)
                    showManualEntry = false
                    showResult = true
                }
                .presentationDetents([.medium, .large], selection: $manualEntryDetent)
            }
            .sheet(isPresented: $showCamera) {
                CameraCaptureView { image in
                    showCamera = false
                    processLabelImage(image)
                } onCancel: {
                    showCamera = false
                }
                .ignoresSafeArea()
            }
            .navigationDestination(isPresented: $showResult) {
                if let result = store.latestResult {
                    ResultView(result: result)
                }
            }
            .onChange(of: selectedPhotoItem) { _, item in
                loadPhoto(item)
            }
        }
        .background(ClearHalalTheme.background.ignoresSafeArea())
    }

    private func startCameraScan() {
        scanError = nil
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            scanError = "Camera is not available in this simulator. Upload a label photo or type ingredients."
            return
        }
        showCamera = true
    }

    private var greeting: String {
        let trimmedName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Good afternoon" : "Good afternoon, \(trimmedName)"
    }

    private func loadPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        scanError = nil
        isReadingLabel = true

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    throw LabelTextRecognitionError.imageNotReadable
                }
                await recognizeAndCheck(image)
            } catch {
                await MainActor.run {
                    scanError = error.localizedDescription
                    isReadingLabel = false
                }
            }
            await MainActor.run {
                selectedPhotoItem = nil
            }
        }
    }

    private func processLabelImage(_ image: UIImage) {
        scanError = nil
        isReadingLabel = true

        Task {
            await recognizeAndCheck(image)
        }
    }

    private func recognizeAndCheck(_ image: UIImage) async {
        do {
            let text = try await recognizer.recognizeText(from: image)
            await MainActor.run {
                store.check(text)
                isReadingLabel = false
                showResult = true
            }
        } catch {
            await MainActor.run {
                scanError = error.localizedDescription
                isReadingLabel = false
            }
        }
    }
}

private struct SecondaryInputCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SecondaryInputCardContent(icon: icon, title: title, subtitle: subtitle)
        }
        .buttonStyle(.plain)
    }
}

private struct SecondaryInputCardContent: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(ClearHalalTheme.deepForest)
                .frame(width: 34, height: 34)
                .background(ClearHalalTheme.soft)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title)
                .font(.headline)
                .foregroundStyle(ClearHalalTheme.primaryText)
            Text(subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(ClearHalalTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .clearHalalCard()
    }
}

private struct ProcessingLabelCard: View {
    var body: some View {
        HStack(spacing: 14) {
            ProgressView()
                .tint(ClearHalalTheme.deepForest)
            VStack(alignment: .leading, spacing: 4) {
                Text("Reading ingredients")
                    .font(.headline)
                Text("Checking visible ingredient text on device.")
                    .font(.caption)
                    .foregroundStyle(ClearHalalTheme.secondaryText)
            }
            Spacer()
        }
        .padding(18)
        .clearHalalCard()
    }
}

private struct ErrorLabelCard: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ClearHalalTheme.caution)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(ClearHalalTheme.primaryText)
            Spacer()
        }
        .padding(16)
        .background(Color(hex: 0xF7E5BD))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ClearChoicesWeeklyCard: View {
    let progress: ScannerCoachProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredient learning")
                .font(.headline)
            Text(progress.summaryLine)
                .font(.subheadline)
                .foregroundStyle(ClearHalalTheme.secondaryText)
            ProgressView(value: progress.weeklyProgress)
                .tint(ClearHalalTheme.deepForest)
            Text("Keep useful checks ready for the next shop.")
                .font(.caption.weight(.medium))
                .foregroundStyle(ClearHalalTheme.deepForest)
        }
        .padding(22)
        .clearHalalCard()
    }
}

private struct ManualEntryView: View {
    let isCompactDetent: Bool
    let onCheck: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                Text("Type ingredients")
                    .font(.title.bold())
                    .foregroundStyle(ClearHalalTheme.primaryText)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Close")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ClearHalalTheme.deepForest)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(ClearHalalTheme.surface)
                        .clipShape(Capsule())
                }
            }

            Text("Paste or type the ingredient list from the product label.")
                .foregroundStyle(ClearHalalTheme.secondaryText)

            ZStack(alignment: .topLeading) {
                ClearHalalTheme.surface

                if text.isEmpty {
                    Text("e.g. Sugar, glucose syrup, gelatin, citric acid, flavourings, E471")
                        .font(.body)
                        .foregroundStyle(ClearHalalTheme.secondaryText.opacity(0.72))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .font(.body)
                    .foregroundStyle(ClearHalalTheme.primaryText)
                    .tint(ClearHalalTheme.deepForest)
                    .scrollContentBackground(.hidden)
                    .padding(12)
            }
                .frame(minHeight: isCompactDetent ? 180 : 260, maxHeight: isCompactDetent ? 220 : 360)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(ClearHalalTheme.border)
                }

            Button {
                onCheck(trimmedText)
            } label: {
                Text("Check ingredients")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(ClearHalalTheme.deepForest)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(trimmedText.isEmpty)
            .opacity(trimmedText.isEmpty ? 0.48 : 1)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, isCompactDetent ? 64 : 46)
        .padding(.bottom, 24)
        .background(ClearHalalTheme.background)
    }
}
