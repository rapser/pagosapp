//
//  CalendarService.swift
//  pagosApp
//
//  Created by miguel tomairo on 26/12/25.
//


import Foundation

/// Protocol for calendar service (ISP + DIP)
protocol CalendarService {
    func addEvent(for payment: Payment, completion: @escaping (String?) -> Void) async
    func updateEvent(for payment: Payment) async
    func removeEvent(for payment: Payment) async
}
