import UIKit
import Checkout

class DefaultPaymentViewModel: PaymentViewModel {
  var updateLoading: (() -> Void)?
  var updateEditBillingSummaryView: (() -> Void)?
  var updateAddBillingDetailsView: (() -> Void)?
  var updateExpiryDateView: (() -> Void)?
  var updateCardNumberView: (() -> Void)?
  var updateSecurityCodeViewStyle: (() -> Void)?
  var updatePayButtonView: (() -> Void)?
  var updateHeaderView: (() -> Void)?
  var updateSecurityCodeViewScheme: ((Card.Scheme) -> Void)?
  var shouldEnablePayButton: ((Bool) -> Void)?
  var cardTokenRequested: ((Result<TokenDetails, TokenisationError.TokenRequest>) -> Void)?
  var supportedSchemes: [Card.Scheme]
  var cardValidator: CardValidator
  var logger: FramesEventLogging
  var checkoutAPIService: CheckoutAPIProtocol
  var paymentFormStyle: PaymentFormStyle?
  var billingFormStyle: BillingFormStyle?
  var currentScheme: Card.Scheme = .unknown
  var billingFormData: BillingForm?
  var isLoading = false {
    didSet {
      updateLoading?()
    }
  }

  private var cardDetails = CardCreationModel() {
    didSet {
      shouldEnablePayButton?(cardDetails.expiryDate != nil && cardDetails.number != nil)
    }
  }

  init(checkoutAPIService: CheckoutAPIProtocol,
       cardValidator: CardValidator,
       logger: FramesEventLogging,
       billingFormData: BillingForm?,
       paymentFormStyle: PaymentFormStyle?,
       billingFormStyle: BillingFormStyle?,
       supportedSchemes: [Card.Scheme]) {
    self.checkoutAPIService = checkoutAPIService
    self.supportedSchemes = NSOrderedSet(array: supportedSchemes).array as? [Card.Scheme] ?? []
    self.cardValidator = cardValidator
    self.paymentFormStyle = paymentFormStyle
    self.billingFormStyle = billingFormStyle
    self.logger = logger

    if let billingFormData = billingFormData {
      updateBillingData(to: billingFormData)
    }
  }

  func viewControllerWillAppear() {
    logger.log(.paymentFormPresented)
  }

  func updateAll() {
    updateHeaderView?()
    updateCardNumberView?()
    updateExpiryDateView?()
    updateSecurityCodeViewStyle?()
    updatePayButtonView?()
    if isAddBillingSummaryNotUpdated() {
      updateBillingSummaryView()
    }
  }

  func updateBillingSummaryView() {
    guard paymentFormStyle?.editBillingSummary != nil else { return }
    var summaryValue = [String?]()

    billingFormStyle?.cells.forEach {
      switch $0 {
        case .fullName: summaryValue.append(billingFormData?.name)
        case .addressLine1: summaryValue.append(billingFormData?.address?.addressLine1)
        case .addressLine2: summaryValue.append(billingFormData?.address?.addressLine2)
        case .state: summaryValue.append(billingFormData?.address?.state)
        case .country: summaryValue.append(billingFormData?.address?.country?.name)
        case .city: summaryValue.append(billingFormData?.address?.city)
        case .postcode: summaryValue.append(billingFormData?.address?.zip)
        case .phoneNumber: summaryValue.append(billingFormData?.phone?.number)
      }
    }

    let summary = updateSummaryValue(with: summaryValue)
    guard !summary.isEmpty else {
      let addBillingSummary = paymentFormStyle?.addBillingSummary ?? DefaultAddBillingDetailsViewStyle()
      paymentFormStyle?.addBillingSummary = addBillingSummary
      updateAddBillingDetailsView?()
      return
    }
    paymentFormStyle?.editBillingSummary?.summary?.text = summary
    updateEditBillingSummaryView?()
  }

  private func updateBillingData(to billingForm: BillingForm) {
    self.billingFormData = billingForm
    cardDetails.phone = billingForm.phone
    cardDetails.billingAddress = billingForm.address
    if let billingName = billingForm.name {
      cardDetails.name = billingName
    }
    if isAddBillingSummaryNotUpdated() {
      updateBillingSummaryView()
    }
  }

  private func isAddBillingSummaryNotUpdated() -> Bool {
    guard billingFormData?.address != nil ||
            billingFormData?.phone != nil else {
      let addBillingSummary = paymentFormStyle?.addBillingSummary ?? DefaultAddBillingDetailsViewStyle()
      paymentFormStyle?.addBillingSummary = addBillingSummary
      updateAddBillingDetailsView?()
      return false
    }
    return true
  }

  private func updateSummaryValue(with summaryValues: [String?]) -> String {
    summaryValues
      .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
      .joined(separator: "\n\n")
  }
}

extension DefaultPaymentViewModel: BillingFormViewModelDelegate {
  func onBillingScreenShown() {
    logger.log(.billingFormPresented)
  }

  func onTapDoneButton(data: BillingForm) {
    updateBillingData(to: data)
  }
}

extension DefaultPaymentViewModel: PaymentViewControllerDelegate {
  func expiryDateIsUpdated(result: Result<ExpiryDate, ExpiryDateError>) {
    switch result {
      case .failure:
        cardDetails.expiryDate = nil
      case .success(let expiryDate):
        cardDetails.expiryDate = expiryDate
    }
  }

  func securityCodeIsUpdated(result: Result<String, SecurityCodeError>) {
    switch result {
      case .failure:
        cardDetails.cvv = ""
      case .success(let cvv):
        cardDetails.cvv = cvv
    }
  }

  func payButtonIsPressed() {
    guard let card = cardDetails.getCard() else { return }
    isLoading = true
    checkoutAPIService.createToken(.card(card)) { [weak self] result in
      self?.isLoading = false
      self?.cardTokenRequested?(result)
    }
  }

  func addBillingButtonIsPressed(sender: UINavigationController?) {
    onTapAddressView(sender: sender)
  }

  func editBillingButtonIsPressed(sender: UINavigationController?) {
    onTapAddressView(sender: sender)
  }

  func cardholderIsUpdated(value: String) {
    cardDetails.name = value
  }

  private func onTapAddressView(sender: UINavigationController?) {
    guard let viewController = FramesFactory.getBillingFormViewController(style: billingFormStyle, data: billingFormData, delegate: self) else { return }
    sender?.present(viewController, animated: true)
  }
}

extension DefaultPaymentViewModel: CardNumberViewModelDelegate {
  func update(result: Result<CardInfo, CardNumberError>) {
    switch result {
      case .failure:
        cardDetails.number = ""
      case .success(let cardInfo):
        cardDetails.number = cardInfo.cardNumber
        updateSecurityCodeViewScheme?(cardInfo.scheme)
    }
  }

  func schemeUpdatedEagerly(to newScheme: Card.Scheme) {
    updateSecurityCodeViewScheme?(newScheme)
  }
}
