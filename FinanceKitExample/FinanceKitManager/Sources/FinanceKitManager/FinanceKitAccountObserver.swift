//
//  FinanceKitAccountObserver.swift
//  FinanceApp
//
//  Created by Tanmay Sonawane on 30/06/24.
//
import Foundation
import FinanceKit

@available(iOS 17.4, *)
class FinanceKitAccountObserver {
	
	let account: Account
	private let financeKitManager = FinanceKitManager.shared

	init(account: Account) {
		self.account = account
		loadBalanceHistoryToken()
		loadTransactionHistoryToken()
		Task {
			try? await fetchBalances()
			try? await fetchTransactions()
		}
	}
	
	func stopObserving() {
		balanceObservationTask?.cancel()
		balancesSequence = nil
		balanceObservationTask = nil
		
		transactionObservationTask?.cancel()
		transactionsSequence = nil
		transactionObservationTask = nil
	}
	
	deinit {
		stopObserving()
	}
	
	// MARK: - Balances
	private var balancesHistoryToken: FinanceStore.HistoryToken?
	private var balancesSequence:  FinanceStore.History<AccountBalance>?
	private var balanceObservationTask: Task<Void, Never>?

	// MARK: Fetch
	func fetchBalances() async throws  {
		guard financeKitManager.authorizationStatus == .authorized else { throw CustomError.message(String(localized:"Unauthorized. Please grant access to your Wallet."))}
		
		let balancesSequence = financeKitManager.store.accountBalanceHistory(forAccountID: UUID(uuidString: account.id)!, since: balancesHistoryToken, isMonitoring: true)
		self.balancesSequence = balancesSequence
		
		balanceObservationTask = Task { [weak self] in
			do {
				for try await change in balancesSequence {
					guard let self = self else { return }
					await account.financeKitBalancesUpdated(inserted: change.inserted, updated: change.updated, deleted: change.deleted)
					updateBalanceHistoryToken(token: change.newToken)
				}
			} catch {
				print("Error observing balances: \(error)")
			}
		}
	}
	
	// MARK: User Defaults - Balance History Token
	func updateBalanceHistoryToken(token: FinanceStore.HistoryToken) {
		self.balancesHistoryToken = token
		let data = try? JSONEncoder().encode(token)
		UserPreferences.userDefaults.setValue(data, forKey: FinanceKitManager.HistoryTokenKey.balances.key + account.id)
	}
	
	private func loadBalanceHistoryToken() {
		guard let data = UserPreferences.userDefaults.data(forKey: FinanceKitManager.HistoryTokenKey.balances.key + account.id) else {
			return
		}
		balancesHistoryToken = try? JSONDecoder().decode(FinanceStore.HistoryToken.self, from: data)
	}
	
	// MARK: - Transactions
	private var transactionHistoryToken: FinanceStore.HistoryToken?
	private var transactionsSequence:  FinanceStore.History<FinanceKit.Transaction>?
	private var transactionObservationTask: Task<Void, Never>?

	// MARK: Fetch
	func fetchTransactions() async throws  {
		guard financeKitManager.authorizationStatus == .authorized else { throw CustomError.message(String(localized:"Unauthorized. Please grant access to your Wallet."))}

		let transactionsSequence = financeKitManager.store.transactionHistory(forAccountID: UUID(uuidString: account.id)!, since: transactionHistoryToken, isMonitoring: true)
		self.transactionsSequence = transactionsSequence
		
		transactionObservationTask = Task { [weak self] in
			do {
				for try await change in transactionsSequence {
					guard let self = self else { return }
					await account.financeKitTransactionsUpdated(inserted: change.inserted, updated: change.updated, deleted: change.deleted)
					updateTransactionHistoryToken(token: change.newToken)
				}
			} catch {
				print("Error observing txns: \(error)")
			}
		}
	}
	
	// MARK: User Defaults - Transaction History Token
	func updateTransactionHistoryToken(token: FinanceStore.HistoryToken) {
		self.transactionHistoryToken = token
		let data = try? JSONEncoder().encode(token)
		UserPreferences.userDefaults.setValue(data, forKey: FinanceKitManager.HistoryTokenKey.transactions.key + account.id)
	}
	
	private func loadTransactionHistoryToken() {
		guard let data = UserPreferences.userDefaults.data(forKey: FinanceKitManager.HistoryTokenKey.transactions.key + account.id) else {
			return
		}
		transactionHistoryToken = try? JSONDecoder().decode(FinanceStore.HistoryToken.self, from: data)
	}
}
