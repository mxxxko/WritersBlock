import SwiftUI

struct GameDialog: View {
    let title: String
    let message: String
    var primaryLabel: String? = nil
    var primaryIsDestructive: Bool = false
    var primaryAction: (() -> Void)? = nil
    let dismissLabel: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) { onDismiss() }
                }

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.eqText)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(.system(size: 14))
                        .foregroundColor(.eqTextDim)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 18)

                Divider().background(Color.eqBorder)

                VStack(spacing: 0) {
                    if let label = primaryLabel, let action = primaryAction {
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) { action() }
                        } label: {
                            Text(label)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(primaryIsDestructive ? Color(red: 1, green: 0.27, blue: 0.27) : .eqText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                        }
                        Divider().background(Color.eqBorder)
                    }

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) { onDismiss() }
                    } label: {
                        Text(dismissLabel)
                            .font(.system(size: 16, weight: primaryLabel == nil ? .semibold : .regular))
                            .foregroundColor(primaryLabel == nil ? .eqText : .eqTextDim)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                }
            }
            .background(Color.eqSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.eqBorder, lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
            .padding(.horizontal, 44)
            .frame(maxWidth: 340)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.94)))
    }
}
