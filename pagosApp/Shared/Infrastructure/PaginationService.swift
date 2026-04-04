//
//  PaginationService.swift
//  pagosApp
//
//  Generic pagination service to handle paginated data loading
//  Improves performance by loading data in chunks rather than all at once
//

import Foundation

// MARK: - Pagination Models

/// Result wrapper for paginated data
struct PaginatedResult<T: Sendable>: Sendable {
    let items: [T]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    
    var hasNextPage: Bool {
        (page * pageSize) < totalCount
    }
    
    var totalPages: Int {
        guard pageSize > 0 else { return 0 }
        return (totalCount + pageSize - 1) / pageSize
    }
    
    var isFirstPage: Bool {
        page == 1
    }
    
    var isLastPage: Bool {
        !hasNextPage
    }
}

/// Configuration for pagination
struct PaginationConfig {
    let pageSize: Int
    let initialPage: Int
    
    static let `default` = PaginationConfig(pageSize: 20, initialPage: 1)
    static let large = PaginationConfig(pageSize: 50, initialPage: 1)
    static let small = PaginationConfig(pageSize: 10, initialPage: 1)
}

// MARK: - Pagination State

/// State manager for paginated lists
@MainActor
@Observable
final class PaginationState<T: Sendable> {
    var items: [T] = []
    var currentPage: Int = 1
    var totalCount: Int = 0
    var isLoadingMore: Bool = false
    var hasReachedEnd: Bool = false
    
    let config: PaginationConfig
    
    init(config: PaginationConfig = .default) {
        self.config = config
    }
    
    var hasNextPage: Bool {
        (currentPage * config.pageSize) < totalCount
    }
    
    var canLoadMore: Bool {
        !hasReachedEnd && !isLoadingMore
    }
    
    // MARK: - State Mutations
    
    func reset() {
        items = []
        currentPage = 1
        totalCount = 0
        hasReachedEnd = false
    }
    
    func append(_ newItems: [T]) {
        items.append(contentsOf: newItems)
        if newItems.isEmpty || newItems.count < config.pageSize {
            hasReachedEnd = true
        }
    }
    
    func update(with result: PaginatedResult<T>) {
        if result.isFirstPage {
            items = result.items
        } else {
            items.append(contentsOf: result.items)
        }
        currentPage = result.page
        totalCount = result.totalCount
        hasReachedEnd = result.isLastPage
    }
}

// MARK: - Paginated Repository Protocol

/// Protocol for repositories that support pagination
protocol PaginatedRepository {
    associatedtype Item: Sendable
    
    func getItems(page: Int, pageSize: Int) async throws -> PaginatedResult<Item>
    func getTotalCount() async throws -> Int
}

// MARK: - Pagination Helper

/// Helper to apply pagination to in-memory collections
struct PaginationHelper {
    
    /// Apply pagination to an array
    static func paginate<T>(_ items: [T], page: Int, pageSize: Int) -> PaginatedResult<T> where T: Sendable {
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, items.count)
        
        guard startIndex < items.count else {
            return PaginatedResult(items: [], totalCount: items.count, page: page, pageSize: pageSize)
        }
        
        let pageItems = Array(items[startIndex..<endIndex])
        return PaginatedResult(items: pageItems, totalCount: items.count, page: page, pageSize: pageSize)
    }
}

// MARK: - Paginated Data Source Protocol

/// Protocol for ViewModels that support paginated data loading
@MainActor
protocol PaginatedViewModel: AnyObject {
    associatedtype Item: Sendable
    
    var paginationState: PaginationState<Item> { get }
    var isLoading: Bool { get set }
    
    func loadFirstPage() async
    func loadNextPage() async
    func refresh() async
}

/// Default implementation for paginated ViewModels
extension PaginatedViewModel {
    var canLoadMore: Bool {
        !paginationState.hasReachedEnd && !paginationState.isLoadingMore
    }
    
    var shouldShowLoadMore: Bool {
        !paginationState.items.isEmpty && paginationState.hasNextPage
    }
}