import SwiftUI

struct LoadingStateView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ProgressView()
                .tint(.blue)
                .scaleEffect(1.2)

            Text(title)
                .font(.body)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.lg)
    }
}
