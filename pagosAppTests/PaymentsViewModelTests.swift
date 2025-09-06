
import XCTest
@testable import pagosApp

class PaymentsViewModelTests: XCTestCase {

    var viewModel: PaymentsViewModel!

    override func setUpWithError() throws {
        try super.setUpWithError()
        viewModel = PaymentsViewModel()
    }

    override func tearDownWithError() throws {
        viewModel = nil
        try super.tearDownWithError()
    }

    func testAddPayment() throws {
        let initialCount = viewModel.payments.count
        let newPaymentName = "Test Payment"
        let newPaymentAmount = 123.45
        let newPaymentDate = Date()
        let newPaymentCategory = PaymentCategory.suscripcion

        viewModel.addPayment(name: newPaymentName, amount: newPaymentAmount, dueDate: newPaymentDate, category: newPaymentCategory)

        XCTAssertEqual(viewModel.payments.count, initialCount + 1)
        XCTAssertTrue(viewModel.payments.contains(where: { $0.name == newPaymentName }))
    }

    func testUpdatePaymentStatus() throws {
        guard let paymentToUpdate = viewModel.payments.first else {
            XCTFail("No payments to update")
            return
        }

        let initialPaidStatus = paymentToUpdate.isPaid
        viewModel.updatePaymentStatus(payment: paymentToUpdate, isPaid: !initialPaidStatus)

        let updatedPayment = viewModel.payments.first(where: { $0.id == paymentToUpdate.id })
        XCTAssertNotNil(updatedPayment)
        XCTAssertEqual(updatedPayment?.isPaid, !initialPaidStatus)
    }

    func testGetPaymentsForDate() throws {
        let testDate = Date().addingTimeInterval(86400 * 2)
        let paymentsOnTestDate = viewModel.getPayments(for: testDate)
        
        let calendar = Calendar.current
        let expectedPayments = viewModel.payments.filter { calendar.isDate($0.dueDate, inSameDayAs: testDate) }

        XCTAssertEqual(paymentsOnTestDate.count, expectedPayments.count)
    }
}
