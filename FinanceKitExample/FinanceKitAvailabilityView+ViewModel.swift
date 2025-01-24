//
//  FinanceKitAvailabilityView+ViewModel.swift
//  FinanceApp
//
//  Created by Tanmay Sonawane on 30/06/24.
//

import SwiftUI
import Combine
import FinanceKit
import FinanceKitManager

@available(iOS 17.4, *)
extension FinanceKitAvailabilityView {
	class ViewModel: ObservableObject {
		private let financeKitManager = FinanceKitManager.shared
		private var cancellables = Set<AnyCancellable>()
		
		@Published var authorizationState: FinanceKit.AuthorizationStatus = FinanceKitManager.shared.authorizationStatus
		@Published var isAuthorizationInProgress = false
		
		init() {
			financeKitManager.$authorizationStatus
				.sink {[weak self] newValue in
					self?.authorizationState = newValue
				}
				.store(in: &cancellables)
		}
		
		var showView: Bool {
			if financeKitManager.isAvailable,
			   authorizationState != .authorized {
				return true
			}
			return false
		}

		var title: LocalizedStringKey {
			switch financeKitManager.authorizationStatus {
			case .notDetermined, .denied:
				return "Import your financial data safely using Apple's FinanceKit"
			case .authorized:
				return ""
			@unknown default:
				return ""
			}
		}
		
		var message: LocalizedStringKey {
			switch financeKitManager.authorizationStatus {
			case .notDetermined:
				return "Imports and sync Apple Card, Apple Cash & more"
			case .denied:
				return "You previously denied access to FinanceKit. Open Settings > Wallet to manually grant access."
			case .authorized:
				return ""
			@unknown default:
				return ""
			}
		}
		
		var buttonTitle: LocalizedStringKey {
			guard !isAuthorizationInProgress else {
				return "Linking.."
			}
			
			switch financeKitManager.authorizationStatus {
			case .notDetermined:
				return "Link"
			case .denied:
				return "Open Settings"
			case .authorized:
				return ""
			@unknown default:
				return ""
			}
		}
		
		@MainActor func handleButtonAction() async throws -> Bool {
			isAuthorizationInProgress = true

			switch authorizationState {
			case .notDetermined:
				try await financeKitManager.requestAuthorizationStatus()
				
			case .denied:
				if let url = URL(string: UIApplication.openSettingsURLString) {
					// Ask the system to open that URL.
					await UIApplication.shared.open(url)
				}
				
			case .authorized: return true
			default: break
			}
			
			isAuthorizationInProgress = false
			return false
		}
	}
}
