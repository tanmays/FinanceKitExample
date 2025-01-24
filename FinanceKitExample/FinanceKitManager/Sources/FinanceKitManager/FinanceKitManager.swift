//
//  FinanceKitManager.swift
//  FinanceApp
//
//  Created by Tanmay Sonawane on 29/06/24.
//

import Foundation
import FinanceKit

@available(iOS 17.4, *)
public class FinanceKitManager: ObservableObject {
	public static let shared = FinanceKitManager()
	
	let store = FinanceStore.shared
	public let dataService = DataService.shared
	
	@Published public var authorizationStatus: FinanceKit.AuthorizationStatus = .notDetermined
	private var observingAccounts: [FinanceKitAccountObserver] = []
	private var accountsSequence:  FinanceStore.History<FinanceKit.Account>?

	private init() {
		guard isAvailable else { return }

		loadHistoryToken()
		Task {
			await updateAuthorizationStatus()
			try await autoSyncAccounts()
			try await autoSyncBalancesAndTransactionsIfNeeded()
		}
	}
	
	public var isAvailable: Bool {
		let available = FinanceStore.isDataAvailable(.financialData)
		return available
	}
	
	@MainActor private func updateAuthorizationStatus() async {
		try? await self.authorizationStatus = store.authorizationStatus()
	}
	
	@MainActor public func requestAuthorizationStatus() async throws {
		self.authorizationStatus = try await store.requestAuthorization()
		if self.authorizationStatus == .authorized {
			try await autoSyncAccounts()
			try await autoSyncBalancesAndTransactionsIfNeeded()
		}
	}
		
	/// Syncs account updates
	func autoSyncAccounts() async throws {
		guard authorizationStatus == .authorized else { throw CustomError.message(String(localized: "Unauthorized. Please grant access to your Wallet."))}
		
		let accountsSequence = store.accountHistory(since: accountHistoryToken, isMonitoring: true)
		self.accountsSequence = accountsSequence
		
		for try await change in accountsSequence {
			await DataService.shared.financeKitAccountsUpdated(inserted: change.inserted, updated: change.updated, deleted: change.deleted)
			updateHistoryToken(token: change.newToken)
		}
	}
	
	/// Syncs balances and transactions for added FinanceKit accounts.
	func autoSyncBalancesAndTransactionsIfNeeded() async throws {
		guard authorizationStatus == .authorized else { throw CustomError.message(String(localized:"Unauthorized. Please grant access to your Wallet."))}

		let financeKitAccounts = DataService.shared.accounts
		for account in financeKitAccounts {
			// Only add if observation for this account hasn't already started
			guard observingAccounts.first(where: {$0.account.id == account.id}) == nil else { continue }
			let accountObserver = FinanceKitAccountObserver(account: account)
			observingAccounts.append(accountObserver)
			print("FinanceKit: Started observing transactions/balances for account: \(account.title)")
		}
	}
	
	func stopSyncing(account: Account) {
		guard let accountToStop = observingAccounts.first(where: {$0.account.id == account.id}) else { return }
		accountToStop.stopObserving()
		observingAccounts.removeAll(where: {$0.account.id == account.id})
	}
	
	func stopSyncingAll() {
		let _ = observingAccounts.map({$0.stopObserving()})
		observingAccounts.removeAll()
	}
	
	// MARK: User Defaults - Account History Token
	private var accountHistoryToken: FinanceStore.HistoryToken?
	
	private func resetHistoryToken() {
		accountHistoryToken = nil
		UserPreferences.userDefaults.removeObject(forKey: HistoryTokenKey.accounts.key)
	}
	
	private func updateHistoryToken(token: FinanceStore.HistoryToken) {
		self.accountHistoryToken = token
		let data = try? JSONEncoder().encode(token)
		UserPreferences.userDefaults.setValue(data, forKey: HistoryTokenKey.accounts.key)
	}
	
	private func loadHistoryToken() {
		guard let data = UserPreferences.userDefaults.data(forKey: HistoryTokenKey.accounts.key) else {
			return
		}
		accountHistoryToken = try? JSONDecoder().decode(FinanceStore.HistoryToken.self, from: data)
	}
}

@available(iOS 17.4, *)
extension FinanceKitManager {
	enum HistoryTokenKey {
		case accounts, balances, transactions
		
		var key: String {
			switch self {
			case .accounts:
				return "FinanceKitAccountHistoryToken"
			case .balances:
				return "FinanceKitBalanceHistoryToken"
			case .transactions:
				return "FinanceKitTransactionHistoryToken"
			}
		}
	}
}
