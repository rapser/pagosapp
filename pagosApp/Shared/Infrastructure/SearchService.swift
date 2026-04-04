//
//  SearchService.swift
//  pagosApp
//
//  Generic search and filtering service to eliminate duplication across ViewModels
//  Clean Architecture - Shared Infrastructure
//

import Foundation

// MARK: - Search Service Protocol

/// Generic protocol for search and filtering services
protocol SearchService {
    associatedtype Item
    associatedtype Filter
    
    func filter(_ items: [Item], by filter: Filter) -> [Item]
    func search(_ items: [Item], query: String) -> [Item]
}

// MARK: - Payment Search Service

/// Concrete implementation for payment searching and filtering
final class PaymentSearchService: SearchService {
    typealias Item = PaymentUI
    typealias Filter = PaymentFilter
    
    enum PaymentFilter {
        case currentMonth
        case futureMonths
        case byCategory(PaymentCategory)
        case byStatus(Bool) // isPaid
        case byPeriod(from: Date, to: Date)
        case compound([PaymentFilter])
    }
    
    func filter(_ payments: [PaymentUI], by filter: PaymentFilter) -> [PaymentUI] {
        let calendar = Calendar.current
        let now = Date()
        
        switch filter {
        case .currentMonth:
            return payments.filter { calendar.isDate($0.dueDate, equalTo: now, toGranularity: .month) }
            
        case .futureMonths:
            guard let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
                  let startOfNextMonth = calendar.date(byAdding: DateComponents(month: 1), to: startOfCurrentMonth) else {
                return []
            }
            return payments.filter { $0.dueDate >= startOfNextMonth }
            
        case .byCategory(let category):
            return payments.filter { $0.category == category }
            
        case .byStatus(let isPaid):
            return payments.filter { $0.isPaid == isPaid }
            
        case .byPeriod(let from, let to):
            return payments.filter { $0.dueDate >= from && $0.dueDate <= to }
            
        case .compound(let filters):
            return filters.reduce(payments) { result, filter in
                self.filter(result, by: filter)
            }
        }
    }
    
    func search(_ payments: [PaymentUI], query: String) -> [PaymentUI] {
        guard !query.isEmpty else { return payments }
        
        let lowercaseQuery = query.lowercased()
        return payments.filter { payment in
            payment.name.lowercased().contains(lowercaseQuery) ||
            payment.category.rawValue.lowercased().contains(lowercaseQuery) ||
            String(payment.amount).contains(lowercaseQuery)
        }
    }
}

// MARK: - Reminder Search Service

/// Concrete implementation for reminder searching and filtering  
final class ReminderSearchService: SearchService {
    typealias Item = Reminder
    typealias Filter = ReminderFilter
    
    enum ReminderFilter {
        case currentMonth
        case futureMonths
        case byType(ReminderType)
        case upcoming(days: Int)
        case overdue
        case byPeriod(from: Date, to: Date)
        case compound([ReminderFilter])
    }
    
    func filter(_ reminders: [Reminder], by filter: ReminderFilter) -> [Reminder] {
        let now = Date()
        let calendar = Calendar.current
        
        switch filter {
        case .currentMonth:
            return reminders.filter { calendar.isDate($0.dueDate, equalTo: now, toGranularity: .month) }
            
        case .futureMonths:
            guard let startOfCurrentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
                  let startOfNextMonth = calendar.date(byAdding: DateComponents(month: 1), to: startOfCurrentMonth) else {
                return []
            }
            return reminders.filter { $0.dueDate >= startOfNextMonth }
            
        case .byType(let type):
            return reminders.filter { $0.reminderType == type }
            
        case .upcoming(let days):
            let futureDate = calendar.date(byAdding: .day, value: days, to: now) ?? now
            return reminders.filter { $0.dueDate >= now && $0.dueDate <= futureDate }
            
        case .overdue:
            return reminders.filter { $0.dueDate < now }
            
        case .byPeriod(let from, let to):
            return reminders.filter { $0.dueDate >= from && $0.dueDate <= to }
            
        case .compound(let filters):
            return filters.reduce(reminders) { result, filter in
                self.filter(result, by: filter)
            }
        }
    }
    
    func search(_ reminders: [Reminder], query: String) -> [Reminder] {
        guard !query.isEmpty else { return reminders }
        
        let lowercaseQuery = query.lowercased()
        return reminders.filter { reminder in
            reminder.title.lowercased().contains(lowercaseQuery) ||
            reminder.description.lowercased().contains(lowercaseQuery) ||
            reminder.reminderType.rawValue.lowercased().contains(lowercaseQuery)
        }
    }
}

// MARK: - Legacy Filter Adapters

/// Adapter to map legacy filters to new unified system
extension PaymentSearchService.PaymentFilter {
    
    /// Convert PaymentFilterUI to unified filter system
    static func from(_ legacyFilter: PaymentFilterUI) -> PaymentSearchService.PaymentFilter {
        switch legacyFilter {
        case .currentMonth:
            return .currentMonth
        case .futureMonths:
            return .futureMonths
        }
    }
    
    /// Convert PaymentHistoryFilter to unified filter system
    static func from(_ legacyFilter: PaymentHistoryFilter) -> PaymentSearchService.PaymentFilter {
        switch legacyFilter {
        case .completed:
            return .byStatus(true)
        case .overdue:
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            return .compound([
                .byStatus(false),
                .byPeriod(from: Date.distantPast, to: yesterday)
            ])
        case .all:
            return .compound([]) // No filtering
        }
    }
}

// MARK: - Reminder Filter Adapter

extension ReminderSearchService.ReminderFilter {
    /// Convert ReminderFilterUI to unified filter system
    static func from(_ filter: ReminderFilterUI) -> ReminderSearchService.ReminderFilter {
        switch filter {
        case .currentMonth:
            return .currentMonth
        case .futureMonths:
            return .futureMonths
        }
    }
}