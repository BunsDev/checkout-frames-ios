import CheckoutEventLoggerKit
import XCTest

@testable import Frames

final class FramesLogEventTests: XCTestCase {

    // MARK: - typeIdentifier

    func test_typeIdentifier_paymentFormPresented_returnsCorrectValue() {

        let subject = FramesLogEvent.paymentFormPresented
        XCTAssertEqual("com.checkout.frames-mobile-sdk.payment_form_presented", subject.typeIdentifier)
    }

    func test_typeIdentifier_exception_returnsCorrectValue() {

        let subject = createExceptionEvent()
        XCTAssertEqual("com.checkout.frames-mobile-sdk.exception", subject.typeIdentifier)
    }

    // MARK: - monitoringLevel

    func test_monitoringLevel_paymentFormPresented_returnsCorrectValue() {

        let subject = FramesLogEvent.paymentFormPresented
        XCTAssertEqual(.info, subject.monitoringLevel)
    }

    func test_monitoringLevel_exception_returnsCorrectValue() {

        let subject = createExceptionEvent()
        XCTAssertEqual(.error, subject.monitoringLevel)
    }

    // MARK: - properties

    func test_properties_paymentFormPresented_returnsCorrectValue() {

        let subject = FramesLogEvent.paymentFormPresented
        XCTAssertEqual([:], subject.properties)
    }

    func test_properties_exception_returnsCorrectValue() {

        let subject = createExceptionEvent(message: "message")
        XCTAssertEqual([.message: "message"], subject.properties)
    }

    // MARK: - Utility

    private func createExceptionEvent(message: String = "") -> FramesLogEvent {

        return .exception(message: message)
    }

}
