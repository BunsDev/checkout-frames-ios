import UIKit

protocol ButtonViewDelegate: AnyObject {
    func selectionButtonIsPressed(sender: UIView)
}

class ButtonView: UIView {
    weak var delegate: ButtonViewDelegate?
    var style: ElementButtonStyle?
    lazy var constraintLeading: NSLayoutConstraint? = buttonTextLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 120.0)

    var isEnabled: Bool = true {
        didSet {
            if let style = style {
                updateLabelStyle(with: style)
            }
        }
    }

    lazy var button: UIButton = {
        let view = UIButton().disabledAutoresizingIntoConstraints()
        view.addTarget(self, action: #selector(selectionButtonIsPressed), for: .touchUpInside)
        return view
    }()

    private(set) lazy var buttonTextLabel: LabelView = {
        LabelView().disabledAutoresizingIntoConstraints()
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupConstraintsInOrder()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(with style: ElementButtonStyle) {
        self.style = style
        backgroundColor = style.backgroundColor
        layer.cornerRadius = style.cornerRadius
        button.layer.cornerRadius = style.cornerRadius
        isEnabled = style.isEnabled
        updateButtonStyle(with: style)
        updateLabelStyle(with: style)
    }

    @objc private func selectionButtonIsPressed() {
        delegate?.selectionButtonIsPressed(sender: self)
    }

    private func updateButtonStyle(with style: ElementButtonStyle) {
        button.tintColor = .clear
        button.clipsToBounds = true
        button.layer.borderColor = style.normalBorderColor.cgColor
        button.layer.borderWidth = style.borderWidth
        button.setTitleColor(style.disabledTextColor, for: .disabled)
        button.setTitleColor(style.textColor, for: .normal)
    }

    private func updateLabelStyle(with style: ElementButtonStyle) {
        button.isEnabled = isEnabled
        let buttonTextLabelStyle = DefaultHeaderLabelFormStyle(text: style.text,
                                                               font: style.font,
                                                               textColor: isEnabled ? style.textColor : style.disabledTextColor)
        buttonTextLabel.update(with: buttonTextLabelStyle)
        constraintLeading?.constant = style.textLeading
        constraintLeading?.priority = .required
        constraintLeading?.isActive = true
    }

    private func setupConstraintsInOrder() {
        setupButtonTextLabel()
        setupButton()
    }

    private func setupButton() {
        addSubview(button)
        button.setupConstraintEqualTo(view: self)
    }

    private func setupButtonTextLabel() {
        addSubview(buttonTextLabel)
        NSLayoutConstraint.activate([
            buttonTextLabel.topAnchor.constraint(equalTo: topAnchor),
            buttonTextLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            buttonTextLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
