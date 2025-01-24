//
//  FinanceKitAvailabilityView.swift
//  Finma
//
//  Created by Tanmay Sonawane on 29/06/24.
//

import SwiftUI

@available(iOS 17.4, *)
struct FinanceKitAvailabilityView: View {
	@StateObject private var viewModel = ViewModel()

	var body: some View {
		if viewModel.showView {
			HStack {
				Image("Apple-Wallet-Logo")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(height: 60)
					.symbolRenderingMode(.palette)
					.foregroundStyle(
						.linearGradient(colors: [.red, .orange, .pink, .red], startPoint: .top, endPoint: .bottomTrailing)
					)
					.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
				
				VStack(alignment: .leading) {
					Text("Apple Wallet Sync")
						.foregroundStyle(.primary)
					Text(viewModel.message)
						.font(.footnote)
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
			
				Spacer(minLength: 0)
				
				Button {
					buttonTapped()
				} label: {
					Text(viewModel.buttonTitle)
				}
			}
			.animation(.easeInOut, value: viewModel.buttonTitle)
			.padding(12)
			.background(Color(UIColor.systemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
			.padding()
		}
	}
	
	private func buttonTapped() {
		Task {
			do {
				let didSucceed = try await viewModel.handleButtonAction()
				if didSucceed {
					print("FinanceKit Authorized!")
				}
			} catch (let error) {
				print(error.localizedDescription)
			}
		}
	}
}

@available(iOS 17.4, *)
struct FinanceKitAvailabilityView_Previews: PreviewProvider {
	static var previews: some View {
		VStack(spacing: 40) {
			FinanceKitAvailabilityView()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
		.background(Color(UIColor.systemBackground))
	}
}
