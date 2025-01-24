//
//  Balance.swift
//  FinanceKitManager
//
//  Created by Tanmay Sonawane on 24/01/25.
//

import Foundation
import FinanceKit

@available(iOS 17.4, *)
public class Balance: Codable {
	public var id: UUID
	public var date: Date
	public var amount: Double
	
	init(id: UUID, date: Date, amount: Double) {
		self.id = id
		self.date = date
		self.amount = amount
	}
	
	convenience init?(financeKitBalance: AccountBalance) {
		guard let amount = financeKitBalance.amount,
		let date = financeKitBalance.date else { return nil }
		self.init(id: financeKitBalance.id, date: date, amount: amount)
	}
	
	func update(using financeKitBalance: AccountBalance) {
		guard let amount = financeKitBalance.amount,
			  let date = financeKitBalance.date else { return }
		self.date = date
		self.amount = amount
	}
}
