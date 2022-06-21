import Foundation
import UIKit
import CheckoutEventLoggerKit
import Checkout

/// A view controller that allows the user to enter card information.
public class CardViewController: UIViewController,
    AddressViewControllerDelegate,
    CardNumberInputViewDelegate,
    CvvInputViewDelegate,
    UITextFieldDelegate {

    // MARK: - Properties

    /// Card View
    public let cardView: CardView
    let cardUtils = CardUtils()

    let checkoutAPIService: CheckoutAPIProtocol?
    let billingFormStyle: BillingFormStyle?
    let cardHolderNameState: InputState
    let billingDetailsState: InputState

    public var billingFormData: BillingForm?
    var notificationCenter = NotificationCenter.default
    public let addressViewController: AddressViewController

    /// List of available schemes
    /// Potential Task : rename amex , diners in checkout sdk keep it sync with frames scheme names
    public var availableSchemes: [Card.Scheme] = [
      .visa,
      .mastercard,
      .americanExpress,
      .dinersClub,
      .discover,
      .jcb
    ]

    /// Delegate
    public weak var delegate: CardViewControllerDelegate?

    // Scheme Icons
    private var lastSelected: UIImageView?

    /// Right bar button item
    public lazy var rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save,
                                                    target: self,
                                                    action: #selector(onTapDoneCardButton))

    var topConstraint: NSLayoutConstraint?

    private var suppressNextLog = false
    private(set) var isNewUI = false
    // MARK: - Initialization

    /// Returns a newly initialized view controller with the cardholder's name and billing details
    /// state specified. You can specified the region using the Iso2 region code ("UK" for "United Kingdom")

    public convenience init(isNewUI: Bool,
                            checkoutAPIService: CheckoutAPIService,
                            billingFormData: BillingForm?,
                            cardHolderNameState: InputState,
                            billingDetailsState: InputState,
                            billingFormStyle: BillingFormStyle?,
                            defaultRegionCode: String? = nil) {
        self.init(isNewUI: isNewUI,
                  checkoutAPIService: checkoutAPIService as CheckoutAPIProtocol,
                  billingFormData: billingFormData,
                cardHolderNameState: cardHolderNameState,
                billingDetailsState: billingDetailsState,
                billingFormStyle: billingFormStyle,
                defaultRegionCode: defaultRegionCode)
    }

    init(isNewUI: Bool,
         checkoutAPIService: CheckoutAPIProtocol,
         billingFormData: BillingForm?,
         cardHolderNameState: InputState,
         billingDetailsState: InputState,
         billingFormStyle: BillingFormStyle? = nil,
         defaultRegionCode: String? = nil) {
        self.isNewUI = isNewUI
        self.checkoutAPIService = checkoutAPIService
        self.billingFormData = billingFormData
        self.cardHolderNameState = cardHolderNameState
        self.billingDetailsState = billingDetailsState
        self.billingFormStyle = billingFormStyle
        cardView = CardView(isNewUI: isNewUI,
                            billingFormData: billingFormData,
                            cardHolderNameState: cardHolderNameState,
                            billingDetailsState: billingDetailsState,
                            cardValidator: checkoutAPIService.cardValidator)
        addressViewController = AddressViewController(initialCountry: "you", initialRegionCode: defaultRegionCode)
        super.init(nibName: nil, bundle: nil)
        updateBillingFormDetailsInputView(data: billingFormData)
    }

    /// Returns a newly initialized view controller with the nib file in the specified bundle.
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Foundation.Bundle?) {
        cardHolderNameState = .required
        billingDetailsState = .required
        cardView = CardView(isNewUI: isNewUI, billingFormData: billingFormData, cardHolderNameState: cardHolderNameState, billingDetailsState: billingDetailsState, cardValidator: nil)
        addressViewController = AddressViewController()
        checkoutAPIService = nil
        billingFormStyle = nil
        billingFormData = nil
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    /// Returns an object initialized from data in a given unarchiver.
    required public init?(coder aDecoder: NSCoder) {
        cardHolderNameState = .required
        billingDetailsState = .required
        cardView = CardView(isNewUI: isNewUI, billingFormData: billingFormData, cardHolderNameState: cardHolderNameState, billingDetailsState: billingDetailsState, cardValidator: nil)
        addressViewController = AddressViewController()
        checkoutAPIService = nil
        billingFormStyle = nil
        billingFormData = nil
        super.init(coder: aDecoder)
    }

    // MARK: - Lifecycle

    /// Called after the controller's view is loaded into memory.
    override public func viewDidLoad() {
        super.viewDidLoad()
        UIFont.loadAllCheckoutFonts
        UITextField.disableHardwareLayout()
        // TODO: Fix overridden values
        rightBarButtonItem.target = self
        rightBarButtonItem.action = #selector(onTapDoneCardButton)
        navigationItem.rightBarButtonItem = rightBarButtonItem
        navigationItem.rightBarButtonItem?.isEnabled = false
        // add gesture recognizer
        cardView.addressTapGesture.addTarget(self, action: #selector(onTapAddressView))
        cardView.billingDetailsInputView.addGestureRecognizer(cardView.addressTapGesture)
        cardView.delegate = self

        addressViewController.delegate = self
        addTextFieldsDelegate()

        // add schemes icons
        view.backgroundColor = .groupTableViewBackground
        cardView.schemeIconsStackView.setIcons(schemes: availableSchemes)
        setInitialDate()

        self.automaticallyAdjustsScrollViewInsets = false

    }

    /// Notifies the view controller that its view is about to be added to a view hierarchy.
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        customizeNavigationBarAppearance()
        title = "cardViewControllerTitle".localized(forClass: CardViewController.self)
        registerKeyboardHandlers(notificationCenter: notificationCenter,
                                 keyboardWillShow: #selector(keyboardWillShow),
                                 keyboardWillHide: #selector(keyboardWillHide))

        if suppressNextLog {
            suppressNextLog = false
        } else {
            checkoutAPIService?.logger.log(.paymentFormPresented)
        }
        navigationController?.isNavigationBarHidden = false

    }

    /// Notifies the view controller that its view is about to be removed from a view hierarchy.
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterKeyboardHandlers(notificationCenter: notificationCenter)
    }

    /// Called to notify the view controller that its view has just laid out its subviews.
    public override func viewDidLayoutSubviews() {
        view.addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.leftAnchor.constraint(equalTo: view.safeLeftAnchor).isActive = true
        cardView.rightAnchor.constraint(equalTo: view.safeRightAnchor).isActive = true

        self.topConstraint = cardView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor)
        if #available(iOS 11.0, *) {
            cardView.topAnchor.constraint(equalTo: view.safeTopAnchor).isActive = true
        } else {
            self.topConstraint?.isActive = true
        }
        cardView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        if #available(iOS 11.0, *) {} else {
            cardView.scrollView.contentSize = CGSize(width: self.view.frame.width,
                                                        height: self.view.frame.height + 10)
        }

    }

    // MARK: Methods
    public func setDefault(regionCode: String) {
        addressViewController.regionCodeSelected = regionCode
    }

    private func setInitialDate() {
        let calendar = Calendar(identifier: .gregorian)
        let date = Date()
        let month = calendar.component(.month, from: date)
        let year = String(calendar.component(.year, from: date))
        let monthString = month < 10 ? "0\(month)" : "\(month)"
        let subYearIndex = year.index(year.startIndex, offsetBy: 2)
        cardView.expirationDateInputView.textField.text =
            "\(monthString)/\(year[subYearIndex...year.index(subYearIndex, offsetBy: 1)])"
    }

    @objc func onTapAddressView() {

        defer {
            suppressNextLog = true
            checkoutAPIService?.logger.log(.billingFormPresented)
        }
        guard isNewUI,
              let billingFormController = BillingFormFactory.getBillingFormViewController(style: billingFormStyle, data: billingFormData, delegate: self)?.navigationController else {
            navigationController?.pushViewController(addressViewController, animated: true)
            return
        }
        navigationController?.present(billingFormController, animated: true)

    }

    @objc func onTapDoneCardButton() {

        cardView.cardNumberInputView.hideError()
        cardView.expirationDateInputView.hideError()
        cardView.cvvInputView.hideError()

        guard let cardValidator = checkoutAPIService?.cardValidator else {
            return
        }

        // Get the values
        let cardNumber = cardView.cardNumberInputView.textField.text!
        let expirationDate = cardView.expirationDateInputView.textField.text!
        let cvv = cardView.cvvInputView.textField.text!

        let cardNumberStandardized = cardNumber.standardize()

        // Validate the values

        // Validate Card Number
        var cardScheme = Card.Scheme.unknown
        switch cardValidator.validate(cardNumber: cardNumber) {
        case .success(let scheme):
            if availableSchemes.contains(where: { scheme == $0 }) {
                cardScheme = scheme
            } else {
                let message = "cardTypeNotAccepted".localized(forClass: CardViewController.self)
                cardView.cardNumberInputView.showError(message: message)
            }
        case .failure(let error):
            switch error {
            case .invalidCharacters:
                let message = "cardNumberInvalid".localized(forClass: CardViewController.self)
                cardView.cardNumberInputView.showError(message: message)
            }
        }

        // Validate CVV
        switch cardValidator.validate(cvv: cvv, cardScheme: cardScheme) {
        case .success:
            print("success cvv validation")
        case .failure:
            let message = "cvvInvalid".localized(forClass: CardViewController.self)
            cardView.cvvInputView.showError(message: message)
        }

        // Potential Task : need to add standardize function to existing checkout SDK for expiry date
        let (expiryMonth, expiryYear) = cardUtils.standardize(expirationDate: expirationDate)

        // Validate Expiry Date
        var cardExpiryDate: ExpiryDate?
        switch cardValidator.validate(expiryMonth: expiryMonth, expiryYear: expiryYear) {
        case .success(let date):
            cardExpiryDate = date
        case .failure:
            let message = "expiryDateInvalid".localized(forClass: CardViewController.self)
            cardView.expirationDateInputView.showError(message: message)
        }

        if !validateCardDetails(cardNumber: cardNumber, cvv: cvv).isEmpty ||
            validateCardExpiryDate(expiryMonth: expiryMonth, expiryYear: expiryYear) != nil {
            return
        }

        guard let checkoutAPIService = checkoutAPIService else {
            return
        }

        self.delegate?.onSubmit(controller: self)

        guard let cardExpiryDate = cardExpiryDate else {
            return // dont silent return
        }

        let card = Card(number: cardNumberStandardized,
                        expiryDate: cardExpiryDate,
                        name: cardView.cardHolderNameInputView.textField.text,
                        cvv: cvv, billingAddress: billingFormData?.address,
                        phone: billingFormData?.phone)

        checkoutAPIService.createToken(.card(card)) { result in
            self.delegate?.onTapDone(controller: self, result: result)
        }
    }

    // MARK: - AddressViewControllerDelegate

    /// Executed when an user tap on the done button.
    public func onTapDoneButton(controller: AddressViewController, address: Address, phone: Phone) {
        billingFormData = BillingForm(name: "", address: address, phone: phone)

        let value = "\(billingFormData?.address?.addressLine1 ?? ""), \(billingFormData?.address?.city ?? "")"
        cardView.billingDetailsInputView.value.text = value
        validateFieldsValues()
        // return to CardViewController
        self.topConstraint?.isActive = false
        controller.navigationController?.popViewController(animated: true)
    }

    private func validateCardDetails(cardNumber: String, cvv: String) -> [Error] {

        var validationError: [Error] = [Error]()
        guard let cardValidator = checkoutAPIService?.cardValidator else {
            return []
        }

        switch cardValidator.validate(cardNumber: cardNumber) {
        case .success(let scheme):
            print(scheme)
            switch cardValidator.validate(cvv: cvv, cardScheme: scheme) {
            case .success:
                print("success")
            case .failure(let error):
                validationError.append(error)
                return validationError
            }
        case .failure(let error):
            validationError.append(error)
            return validationError
        }
        return validationError
    }

    private func validateCardExpiryDate(expiryMonth: String, expiryYear: String) -> Error? {
        guard let cardValidator = checkoutAPIService?.cardValidator else {
            return nil
        }
        switch cardValidator.validate(expiryMonth: expiryMonth, expiryYear: expiryYear) {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }

    private func addTextFieldsDelegate() {
        cardView.cardNumberInputView.delegate = self
        cardView.cardHolderNameInputView.textField.delegate = self
        cardView.expirationDateInputView.textField.delegate = self
        cardView.cvvInputView.delegate = self
        cardView.cvvInputView.onChangeDelegate = self
    }

    private func validateFieldsValues() {
        let cardNumber = cardView.cardNumberInputView.textField.text!
        let expirationDate = cardView.expirationDateInputView.textField.text!
        let cvv = cardView.cvvInputView.textField.text!

        // check card holder's name
        if cardHolderNameState == .required && (cardView.cardHolderNameInputView.textField.text?.isEmpty)! {
            navigationItem.rightBarButtonItem?.isEnabled = false
            return
        }
        // check billing details
        if billingDetailsState == .required && billingFormData?.address == nil {
            navigationItem.rightBarButtonItem?.isEnabled = false
            return
        }
        // values are not empty strings
        if cardNumber.isEmpty || expirationDate.isEmpty ||
            cvv.isEmpty {
            navigationItem.rightBarButtonItem?.isEnabled = false
            return
        }
        navigationItem.rightBarButtonItem?.isEnabled = true
    }

    @objc func keyboardWillShow(notification: NSNotification) {
        scrollViewOnKeyboardWillShow(notification: notification, scrollView: cardView.scrollView, activeField: nil)
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        scrollViewOnKeyboardWillHide(notification: notification, scrollView: cardView.scrollView)
    }

    // MARK: - UITextFieldDelegate

    /// Tells the delegate that editing stopped for the specified text field.
    public func textFieldDidEndEditing(_ textField: UITextField) {
        validateFieldsValues()
    }

    /// Tells the delegate that editing stopped for the textfield in the specified view.
    public func textFieldDidEndEditing(view: UIView) {
        validateFieldsValues()

        guard
            let superView = view as? CardNumberInputView,
            let cardNumber = superView.textField.text
        else {
            return
        }

        let cardNumberStandardized = cardUtils.removeNonDigits(from: cardNumber)
        let scheme = (try? checkoutAPIService?.cardValidator.validate(cardNumber: cardNumberStandardized).get()) ?? .unknown
        cardView.cvvInputView.scheme = scheme
    }

    // MARK: - CardNumberInputViewDelegate

    /// Called when the card number changed.
    public func onChangeCardNumber(scheme: Card.Scheme) {
        // reset if the card number is empty
        if scheme == .unknown && lastSelected != nil {
            cardView.schemeIconsStackView.arrangedSubviews.forEach { $0.alpha = 1 }
            lastSelected = nil
        }
        guard scheme != .unknown else {
            return
        }

        let index = availableSchemes.firstIndex(of: scheme)
        guard let indexScheme = index else { return }
        let imageView = cardView.schemeIconsStackView.arrangedSubviews[indexScheme] as? UIImageView

        if lastSelected == nil {
            cardView.schemeIconsStackView.arrangedSubviews.forEach { $0.alpha = 0.5 }
            imageView?.alpha = 1
            lastSelected = imageView
        } else {
            lastSelected!.alpha = 0.5
            imageView?.alpha = 1
            lastSelected = imageView
        }
    }

    // MARK: CvvInputViewDelegate

    public func onChangeCvv() {
        validateFieldsValues()
    }
}

extension CardViewController: BillingFormViewModelDelegate {

    private func updateBillingFormDetailsInputView(data: BillingForm?) {
        var summaryValue = ""

        func updateSummaryValue(billingFormValue: String?) {
            guard let billingFormValue = billingFormValue else { return }
            let value = billingFormValue.trimmingCharacters(in: .whitespaces)
            if !summaryValue.isEmpty {
                summaryValue.append("\(value)\n\n")
            }
        }

        guard let data = data else { return }
        guard let address = data.address, let phone = data.phone else {
            let style = DefaultPaymentSummaryEmptyDetailsCellStyle()
            cardView.updateBillingFormEmptyDetailsInputView(style: style)
            return
        }
        
        updateSummaryValue(billingFormValue: data.name)
        updateSummaryValue(billingFormValue: address.addressLine1)
        updateSummaryValue(billingFormValue: address.addressLine2)
        updateSummaryValue(billingFormValue: address.city)
        updateSummaryValue(billingFormValue: address.state)
        updateSummaryValue(billingFormValue: address.zip)
        updateSummaryValue(billingFormValue: address.country?.name)
        updateSummaryValue(billingFormValue: phone.number)

        let summaryCellButtonStyle = DefaultSummaryCellButtonStyle(summary:  DefaultTitleLabelStyle(text:summaryValue))
        cardView.updateBillingFormSummaryView(style: summaryCellButtonStyle)
    }

    func onTapDoneButton(data: BillingForm) {
        billingFormData = data

        if isNewUI {
            updateBillingFormDetailsInputView(data: data)
        } else {
            let value = "\(data.address?.addressLine1 ?? ""), \(data.address?.city ?? "")"
            cardView.billingDetailsInputView.value.text = value
        }
        validateFieldsValues()
        // return to CardViewController
        self.topConstraint?.isActive = false
    }
}


extension CardViewController: CardViewDelegate {
    func buttonIsPressed() {
        onTapAddressView()
    }
}
