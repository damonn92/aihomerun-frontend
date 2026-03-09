import SwiftUI
import MapKit

struct FieldSearchBar: View {
    @Binding var searchText: String
    let completions: [MKLocalSearchCompletion]
    let onSearch: (String) -> Void
    let onCompletionTap: (MKLocalSearchCompletion) -> Void
    let onClear: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search input
            HRInputContainer(icon: "magnifyingglass") {
                TextField("Search address or field name...", text: $searchText)
                    .font(.subheadline)
                    .focused($isFocused)
                    .onSubmit { onSearch(searchText) }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        isFocused = false
                        onClear()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            }

            // Autocomplete dropdown
            if isFocused && !completions.isEmpty {
                VStack(spacing: 0) {
                    ForEach(completions, id: \.self) { completion in
                        Button {
                            isFocused = false
                            onCompletionTap(completion)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.hrBlue)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(completion.title)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    if !completion.subtitle.isEmpty {
                                        Text(completion.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.4))
                                            .lineLimit(1)
                                    }
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        if completion != completions.last {
                            Divider()
                                .background(Color.white.opacity(0.06))
                                .padding(.leading, 48)
                        }
                    }
                }
                .background(Color.hrCard)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .padding(.top, 4)
            }
        }
    }
}
