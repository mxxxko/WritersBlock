import SwiftUI
import StoreKit

struct PaywallView: View {
    let storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.eqBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon + headline
                VStack(spacing: 12) {
                    Image(systemName: "infinity.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.eqAmber)

                    Text("Unlock Unlimited Mode")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.eqText)
                        .multilineTextAlignment(.center)

                    Text("Play as many word puzzles as you want,\nwhenever you want.")
                        .font(.system(size: 15))
                        .foregroundColor(.eqTextDim)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Feature list
                VStack(alignment: .leading, spacing: 16) {
                    featureRow("infinity", "Unlimited puzzles for all difficulties")
                    featureRow("bolt.fill", "Earn hint tokens for every solve")
                    featureRow("square.and.arrow.up", "Share puzzle codes with friends")
                    featureRow("checkmark.seal.fill", "One-time purchase · no subscription")
                }
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // Purchase area
                VStack(spacing: 14) {
                    if let error = storeManager.purchaseError {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Button {
                        Task { await storeManager.purchase() }
                    } label: {
                        ZStack {
                            if storeManager.isLoadingProduct || storeManager.isPurchasing {
                                ProgressView().tint(.black)
                            } else {
                                Text("Unlock for \(storeManager.product?.displayPrice ?? "$0.99")")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.eqAmber)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(storeManager.isLoadingProduct || storeManager.isPurchasing)
                    .padding(.horizontal, 24)

                    Button {
                        Task { await storeManager.restorePurchases() }
                    } label: {
                        if storeManager.isRestoring {
                            ProgressView().tint(.eqTextDim)
                                .padding(.vertical, 8)
                        } else {
                            Text("Restore previous purchase")
                                .font(.system(size: 14))
                                .foregroundColor(.eqTextDim)
                                .padding(.vertical, 8)
                        }
                    }
                    .disabled(storeManager.isRestoring)
                }
                .padding(.bottom, 44)
            }

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.eqTextDim)
                    .frame(width: 30, height: 30)
                    .background(Color.eqSurface)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Color.eqBorder, lineWidth: 1))
            }
            .padding(.top, 20)
            .padding(.trailing, 20)
        }
        .onChange(of: storeManager.isUnlocked) { _, unlocked in
            if unlocked { dismiss() }
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.eqAmber)
                .frame(width: 22, alignment: .center)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.eqText)
        }
    }
}
