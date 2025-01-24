//
//  Due.swift
//  FinanceKitManager
//
//  Created by Tanmay Sonawane on 24/01/25.
//

import Foundation

@available(iOS 17.4, *)
public class Due: Codable {
	public var id: UUID
	public var dueAt: Date
	public var paidAt: Date?
	public var totalDue: Double
	public var minDue: Double
	public var amountPaid: Double
	
	init(id: UUID, dueAt: Date, paidAt: Date?, totalDue: Double, minDue: Double, amountPaid: Double) {
		self.id = id
		self.dueAt = dueAt
		self.paidAt = paidAt
		self.totalDue = totalDue
		self.minDue = minDue
		self.amountPaid = amountPaid
	}
	
	convenience init?(accountDetails: AccountDetails) {
		guard let dueAt = accountDetails.nextPaymentDueDate,
			  let totalDue = accountDetails.overduePaymentAmount else {
			return nil
		}
		self.init(id: UUID(), dueAt: dueAt, paidAt: nil, totalDue: totalDue, minDue: accountDetails.minimumNextPaymentAmount ?? 0, amountPaid: 0)
	}
}
