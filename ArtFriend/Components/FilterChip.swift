import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct FilterChipGroup<T: Identifiable & Hashable>: View {
    let items: [T]
    let titleKeyPath: KeyPath<T, String>
    @Binding var selection: T?
    let allTitle: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: allTitle, isSelected: selection == nil) {
                    selection = nil
                }

                ForEach(items) { item in
                    FilterChip(
                        title: item[keyPath: titleKeyPath],
                        isSelected: selection?.id == item.id
                    ) {
                        selection = item
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    VStack {
        FilterChip(title: "All", isSelected: true) {}
        FilterChip(title: "Museum A", isSelected: false) {}
    }
}
