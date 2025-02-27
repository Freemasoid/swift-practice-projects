import UIKit

protocol FloatingInputViewDelegate: AnyObject {
    func didTapSendButton(with text: String)
}

class FloatingInputView: UIView {
    
    // MARK: - Properties
    weak var delegate: FloatingInputViewDelegate?
    
    // MARK: - UI Components
    private(set) var textField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Write a message..."
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.textColor = UIColor(named: K.BrandColours.blue)
        return textField
    }()
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        button.tintColor = UIColor(named: K.BrandColours.lightBlue)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = UIColor(named: K.BrandColours.blue)
        translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(textField)
        addSubview(sendButton)
        
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            textField.centerYAnchor.constraint(equalTo: centerYAnchor),
            textField.heightAnchor.constraint(equalToConstant: 40),
            
            sendButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 20),
            sendButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            sendButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 40),
            sendButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    // MARK: - Actions
    @objc private func sendButtonTapped() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return
        }
        delegate?.didTapSendButton(with: text)
        textField.text = ""
    }
    
    // MARK: - Public Methods
    func clearText() {
        textField.text = ""
    }
}
