import UIKit

class InputView: UIView {

    // MARK: - Properties

    weak var delegate: TextFieldViewDelegate?
    private(set) var style: CellTextFieldStyle?
    private(set) lazy var textFieldContainerBottomAnchor = textFieldContainer.bottomAnchor.constraint(equalTo: errorView.topAnchor)
    private(set) lazy var iconViewWidthAnchor = iconView.widthAnchor.constraint(equalToConstant: 32)

    // MARK: - UI elements

    private(set) lazy var headerLabel: LabelView = {
        LabelView().disabledAutoresizingIntoConstraints()
    }()

    private(set) lazy var mandatoryLabel: LabelView = {
        LabelView().disabledAutoresizingIntoConstraints()
    }()

    private(set) lazy var hintLabel: LabelView = {
        LabelView().disabledAutoresizingIntoConstraints()
    }()

    private(set) lazy var textFieldContainer: UIStackView = {
        let view = UIStackView().disabledAutoresizingIntoConstraints()
        view.axis = .horizontal
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        view.spacing = 16
        view.backgroundColor = .clear
        return view
    }()

    private(set) lazy var textFieldView: TextFieldView = {
        let view = TextFieldView().disabledAutoresizingIntoConstraints()
        view.delegate = self
        return view
    }()

    private lazy var iconView: ImageContainerView = {
        let view = ImageContainerView().disabledAutoresizingIntoConstraints()
        view.isHidden = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewsInOrder()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func textFieldEditingChanged(textField: UITextField) {
        delegate?.textFieldShouldChangeCharactersIn(textField: textField, replacementString: "")
    }

    private(set) lazy var errorView: SimpleErrorView = {
        SimpleErrorView().disabledAutoresizingIntoConstraints()
    }()

    // MARK: - Update subviews style

    func update(style: CellTextFieldStyle){
        self.style = style
        backgroundColor = style.backgroundColor
        mandatoryLabel.isHidden = style.isMandatory

        headerLabel.update(with: style.title)
        mandatoryLabel.update(with: style.mandatory)
        hintLabel.update(with: style.hint)
        updateTextFieldContainer(style: style)
        textFieldView.update(with: style.textfield)

        if let errorStyle = style.error {
            updateErrorView(style: errorStyle)
        }
    }

    private func updateTextFieldContainer(style: CellTextFieldStyle) {
        textFieldContainer.layer.cornerRadius = style.textfield.cornerRadius
        textFieldContainer.layer.borderWidth = style.textfield.borderWidth
        textFieldContainer.backgroundColor = style.textfield.backgroundColor

        let stateUpdate = StateUpdate(errorUpdate: SimpleErrorView.StateUpdate(isHidden: true, labelText: nil), iconUpdate: nil)
        update(state: stateUpdate)
    }

    private func updateErrorView(style: ElementErrorViewStyle) {
        errorView.update(style: style)
        let expectedErrorViewHeight = style.height
//        textFieldContainerBottomAnchor.constant = -(shouldHideErrorView ? 0 : expectedErrorViewHeight)
    }
}

// MARK: - Views Layout Constraint

extension InputView {

    private func setupViewsInOrder() {
        backgroundColor = style?.backgroundColor
        setupHeaderLabel()
        setupMandatoryLabel()
        setupHintLabel()
        setupTextFieldContainer()
        setupIcon()
        setupTextField()
        setupErrorView()
    }

    private func setupHeaderLabel() {
        addSubview(headerLabel)
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: topAnchor),
            headerLabel.leadingAnchor.constraint(equalTo: leadingAnchor)
        ])
    }

    private func setupMandatoryLabel() {
        addSubview(mandatoryLabel)
        NSLayoutConstraint.activate([
            mandatoryLabel.topAnchor.constraint(equalTo: topAnchor),
            mandatoryLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            mandatoryLabel.leadingAnchor.constraint(greaterThanOrEqualTo: headerLabel.trailingAnchor)
        ])
    }

    private func setupHintLabel() {
        addSubview(hintLabel)
        NSLayoutConstraint.activate([
            hintLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor,
                                           constant: Constants.Padding.s.rawValue),
            hintLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            hintLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func setupTextFieldContainer() {
        textFieldContainer.setContentHuggingPriority(.required, for: .vertical)
        addSubview(textFieldContainer)
        NSLayoutConstraint.activate([
            textFieldContainer.topAnchor.constraint(equalTo: hintLabel.bottomAnchor,
                                                    constant: Constants.Padding.s.rawValue),
            textFieldContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            textFieldContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            textFieldContainerBottomAnchor
        ])
    }

    private func setupIcon() {
        textFieldContainer.addArrangedSubview(iconView)

        NSLayoutConstraint.activate([
            iconViewWidthAnchor
        ])
    }

    private func setupTextField() {
        let heightStyle = style?.textfield.height ?? Constants.Style.BillingForm.InputTextField.height.rawValue
        textFieldContainer.addArrangedSubview(textFieldView)
        NSLayoutConstraint.activate([
            textFieldView.heightAnchor.constraint(equalToConstant: heightStyle)
        ])
    }

    private func setupErrorView() {
        addSubview(errorView)

        NSLayoutConstraint.activate([
            errorView.topAnchor.constraint(equalTo: textFieldContainer.bottomAnchor,
                                           constant: Constants.Padding.m.rawValue),
            errorView.leadingAnchor.constraint(equalTo: leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func setBorder(isValid: Bool) {
        guard let style = style else { return }
        textFieldContainer.layer.borderColor = (isValid ? style.textfield.normalBorderColor : style.textfield.errorBorderColor).cgColor
    }
}

// MARK: - Text Field Delegate

extension InputView: TextFieldViewDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        delegate?.textField(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
    }

    func textFieldShouldBeginEditing(textField: UITextField) {
        delegate?.textFieldShouldBeginEditing(textField: textField)
        textFieldContainer.layer.borderColor = style?.textfield.focusBorderColor.cgColor
    }

    func textFieldShouldReturn() -> Bool {
         delegate?.textFieldShouldReturn() ?? false
    }

    func textFieldShouldEndEditing(textField: UITextField, replacementString: String) -> Bool {
        delegate?.textFieldShouldEndEditing(textField: textField, replacementString: replacementString) ?? true
    }

    func textFieldShouldChangeCharactersIn(textField: UITextField, replacementString string: String) {
        delegate?.textFieldShouldChangeCharactersIn(textField: textField, replacementString: string)
    }
}

extension InputView: Stateful {
    struct StateUpdate {
        let errorUpdate: SimpleErrorView.StateUpdate?
      let iconUpdate: ImageContainerView.StateUpdate?
    }

    func update(state update: StateUpdate) {
        if let errorUpdate = update.errorUpdate {
            errorView.update(state: errorUpdate)

            if let isHidden = errorUpdate.isHidden {
              setBorder(isValid: isHidden)
            }
        }

      if let iconUpdate = update.iconUpdate {
          imageContainerView.update(state: iconUpdate)
      }
    }
}
