import UIKit
import Checkout

protocol PaymentViewControllerDelegate: AnyObject {
  func addBillingButtonIsPressed(sender: UINavigationController?)
  func editBillingButtonIsPressed(sender: UINavigationController?)
  func expiryDateIsUpdated(value: ExpiryDate)
  func securityCodeIsUpdated(value: String)
}

final class PaymentViewController: UIViewController {

  // MARK: - Variables

  weak var delegate: PaymentViewControllerDelegate?

  private(set) var viewModel: PaymentViewModel
  private var notificationCenter = NotificationCenter.default

  // MARK: - UI properties

  // TODO: Replace it with new header
  private lazy var headerView: PaymentHeaderView = {
    PaymentHeaderView().disabledAutoresizingIntoConstraints()
  }()

  private lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView().disabledAutoresizingIntoConstraints()
    scrollView.keyboardDismissMode = .onDrag
    return scrollView
  }()

  private lazy var stackView: UIStackView = {
    let view = UIStackView().disabledAutoresizingIntoConstraints()
    view.axis = .vertical
    view.spacing = 20
    return view
  }()

  private lazy var billingFormSummaryView: BillingFormSummaryView = {
    let view = BillingFormSummaryView()
    view.delegate = self
    return view
  }()

  private lazy var addBillingFormButtonView: SelectionButtonView = {
    let view = SelectionButtonView()
    view.delegate = self
    return view
  }()

  private lazy var expiryDateView: ExpiryDateView = {
    let view = ExpiryDateView(cardValidator: viewModel.cardValidator)
    view.delegate = self
    return view
  }()

  private lazy var cardNumberView: CardNumberView = {
    let cardNumberViewModel = CardNumberViewModel(cardValidator: viewModel.cardValidator)
    cardNumberViewModel.delegate = viewModel as? CardNumberViewModelDelegate
    let cardNumberView = CardNumberView(viewModel: cardNumberViewModel)
    return cardNumberView
  }()

  private lazy var securityCodeView: SecurityCodeView = {
    let view = SecurityCodeView(cardValidator: viewModel.cardValidator)
    view.delegate = self
    return view
  }()

  // MARK: - functions

  init(viewModel: PaymentViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    UIFont.loadAllCheckoutFonts
    UITextField.disableHardwareLayout()
    setupNavigationBar()
    view.backgroundColor = .white
    setupViewModel()
    setupViewsInOrder()
    viewModel.updateAll()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    deregisterKeyboardHandlers(notificationCenter: notificationCenter)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
    setUpKeyboard()
    viewModel.viewControllerWillAppear()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupNavigationBar() {
    customizeNavigationBarAppearance(color: viewModel.paymentFormStyle?.headerView.backgroundColor ?? .white)
    navigationController?.navigationBar.tintColor = viewModel.paymentFormStyle?.headerView.headerLabel?.textColor
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: Constants.Bundle.Images.leftArrow.image, style: .plain, target: self, action: #selector(popViewController))
  }

  @objc private func popViewController() {
    self.navigationController?.popViewController(animated: true)
  }

  @objc private func keyboardWillShow(notification: Notification) {
    guard let userInfo = notification.userInfo else { return }
    var keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
    keyboardFrame = view.convert(keyboardFrame, from: nil)
    var contentInset: UIEdgeInsets = scrollView.contentInset
    contentInset.bottom = keyboardFrame.size.height + 20
    updateScrollViewInset(to: contentInset, from: notification)
  }

  @objc private func keyboardWillHide(notification: Notification) {
    updateScrollViewInset(to: .zero, from: notification)
  }

  private func setUpKeyboard() {
    registerKeyboardHandlers(notificationCenter: notificationCenter,
                             keyboardWillShow: #selector(keyboardWillShow),
                             keyboardWillHide: #selector(keyboardWillHide))
  }

  private func updateScrollViewInset(to contentInset: UIEdgeInsets, from notification: Notification) {
    var animationDuration: Double = 0
    if let userInfo = notification.userInfo,
       let notificationAnimationDuration: Double = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
      animationDuration = notificationAnimationDuration
    }
    UIView.animate(withDuration: animationDuration) {
      self.scrollView.contentInset = contentInset
    }
  }
}

// MARK: View Model Integration

extension PaymentViewController {
  private func setupViewModel() {
    delegate = self.viewModel as? PaymentViewControllerDelegate
    setupAddBillingDetailsViewClosure()
    setupEditBillingSummaryViewClosure()
    setupExpiryDateViewClosure()
    setupCardNumberViewClosure()
    setupSecurityCodeViewClosure()
    setupHeaderViewClosure()
  }

  private func setupHeaderViewClosure() {
    viewModel.updateHeaderView = { [weak self] in
      DispatchQueue.main.async {
        self?.updateHeaderView()
      }
    }
  }

  private func setupAddBillingDetailsViewClosure() {
    viewModel.updateAddBillingDetailsView = { [weak self] in
      DispatchQueue.main.async {
        self?.updateAddBillingFormButtonView()
      }
    }
  }

  private func setupEditBillingSummaryViewClosure() {
    viewModel.updateEditBillingSummaryView = { [weak self] in
      DispatchQueue.main.async {
        self?.updateEditBillingSummaryView()
      }
    }
  }

  private func setupExpiryDateViewClosure() {
    viewModel.updateExpiryDateView = { [weak self] in
      DispatchQueue.main.async {
        self?.updateExpiryDate()
      }
    }
  }

  private func setupCardNumberViewClosure() {
    viewModel.updateCardNumberView = { [weak self] in
      DispatchQueue.main.async {
        self?.updateCardNumber()
      }
    }
  }

  private func setupSecurityCodeViewClosure() {
    viewModel.updateSecurityCodeView = { [weak self] cardScheme in
      DispatchQueue.main.async {
        self?.updateSecurityCode(cardScheme: cardScheme)
      }
    }
  }

  private func updateCardNumber() {
    guard let style = viewModel.paymentFormStyle?.cardNumber else { return }
    cardNumberView.update(style: style)
  }

  private func updateExpiryDate() {
    guard let style = viewModel.paymentFormStyle?.expiryDate else { return }
    expiryDateView.update(style: style)
  }

  private func updateSecurityCode(cardScheme: Card.Scheme) {
    guard let style = viewModel.paymentFormStyle?.securityCode else { return }
    securityCodeView.update(style: style, cardScheme: cardScheme)
  }

  private func updateAddBillingFormButtonView() {
    guard let style = viewModel.paymentFormStyle?.addBillingSummary else { return }
    addBillingFormButtonView.isHidden = false
    billingFormSummaryView.isHidden = true
    addBillingFormButtonView.update(style: style)
  }

  private func updateEditBillingSummaryView() {
    guard let style = viewModel.paymentFormStyle?.editBillingSummary else { return }
    addBillingFormButtonView.isHidden = true
    billingFormSummaryView.isHidden = false
    billingFormSummaryView.update(style: style)
  }

  public func updateHeaderView() {
    guard let style = viewModel.paymentFormStyle?.headerView else { return }
    headerView.update(style: style)
  }
}

// MARK: Setup Views

extension PaymentViewController {
  private func setupViewsInOrder() {
    setupScrollView()
    setupStackView()
    addArrangedSubviewForStackView()
  }

  private func addArrangedSubviewForStackView() {
    stackView.addArrangedSubview(headerView)
    stackView.addArrangedSubview(cardNumberView)
    stackView.addArrangedSubview(expiryDateView)
    stackView.addArrangedSubview(securityCodeView)
    stackView.addArrangedSubview(addBillingFormButtonView)
    stackView.addArrangedSubview(billingFormSummaryView)
  }

  func setupScrollView() {
    view.addSubview(scrollView)
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeTopAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
    ])
  }

  func setupStackView() {
    scrollView.addSubview(stackView)
    stackView.setupConstraintEqualTo(view: scrollView, constant: Constants.Padding.l.rawValue)
    stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -Constants.Padding.xxxl.rawValue).isActive = true
  }
}

extension PaymentViewController: SelectionButtonViewDelegate {
  func selectionButtonIsPressed() {
    delegate?.addBillingButtonIsPressed(sender: navigationController)
  }
}

extension PaymentViewController: BillingFormSummaryViewDelegate {
  func summaryButtonIsPressed() {
    delegate?.editBillingButtonIsPressed(sender: navigationController)
  }
}

extension PaymentViewController: ExpiryDateViewDelegate {
  func update(expiryDate: ExpiryDate) {
    delegate?.expiryDateIsUpdated(value: expiryDate)
  }
}

extension PaymentViewController: SecurityCodeViewDelegate {
  func update(securityCode: String) {
    delegate?.securityCodeIsUpdated(value: securityCode)
  }
}
