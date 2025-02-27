// MARK: - Imports
import UIKit
import Supabase

// MARK: - ChatViewController
class ChatViewController: UIViewController {
    
    // MARK: - Properties
    private let supabase = SupabaseManager.shared.supabase
    private var messages: [Message] = []
    private var messagesChannel: RealtimeChannelV2?
    private var listenerTask: Task<Void, Never>?
    private var isListenerSetup: Bool = false
    private var currentUserEmail: String?
    
    // MARK: - UI Properties
    private var floatingInputView: FloatingInputView!
    private var originalTableViewBottomInset: CGFloat = 0
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var messageTextfield: UITextField!
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setupTableView()
        setupKeyboardHandling()
        
        Task {
            await fetchCurrentUserEmail()
            await fetchMessages()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        floatingInputView.isHidden = false
        addKeyboardObservers()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObservers()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        title = K.appName
        navigationItem.hidesBackButton = true
        setupFloatingInputView()
        originalTableViewBottomInset = tableView.contentInset.bottom
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.isScrollEnabled = true
        tableView.alwaysBounceVertical = true
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), 
                         forCellReuseIdentifier: K.cellIdentifier)
        setupTableViewConstraints()
    }
    
    private func setupTableViewConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60)
        ])
    }
    
    // MARK: - Input View Setup
    private func setupFloatingInputView() {
        floatingInputView = FloatingInputView()
        floatingInputView.delegate = self
        
        if let window = getKeyWindow() {
            window.addSubview(floatingInputView)
            
            NSLayoutConstraint.activate([
                floatingInputView.leadingAnchor.constraint(equalTo: window.leadingAnchor),
                floatingInputView.trailingAnchor.constraint(equalTo: window.trailingAnchor),
                floatingInputView.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor),
                floatingInputView.heightAnchor.constraint(equalToConstant: 60)
            ])
        }
    }
    
    private func getKeyWindow() -> UIWindow? {
        // For iOS 15 and later
        if #available(iOS 15.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            return windowScene?.windows.first(where: { $0.isKeyWindow })
        }
        // For iOS 13 and 14
        else {
            return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
        }
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardHandling() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func addKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Message Handling
    private func fetchCurrentUserEmail() async {
        do {
            currentUserEmail = try await supabase.auth.session.user.email
        } catch {
            print("Error fetching current user email: \(error)")
        }
    }
    
    private func sendMessage() async {
        do {
            guard let messageBody = floatingInputView.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), 
                  !messageBody.isEmpty else { return }
            
            var userEmail = currentUserEmail
            if userEmail == nil {
                try userEmail = await supabase.auth.session.user.email
                currentUserEmail = userEmail
            }
            
            guard let email = userEmail else {
                print("Could not get user email")
                return
            }
            
            try await supabase
                .from("messages")
                .insert([["sender": email, "messageBody": messageBody]])
                .execute()
            
            floatingInputView.clearText()
            print("message sent")
        } catch {
            print("failed to send a message")
            debugPrint(error)
        }
    }
    
    private func fetchMessages() async {
        messages = []
        
        do {
            let response = try await supabase
                .from("messages")
                .select("sender, messageBody")
                .order("created_at", ascending: true)
                .execute()
            
            messages = try parseMessages(from: response.data)
            
            await MainActor.run {
                tableView.reloadData()
                scrollToBottom()
            }
            
            if !isListenerSetup {
                await setupRealtimeListener()
                isListenerSetup = true
            }
            
        } catch {
            print("failed to load messages")
            debugPrint(error)
        }
    }
    
    private func parseMessages(from data: Data) throws -> [Message] {
        let decodedData = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return decodedData.compactMap { messageDict in
            guard let sender = messageDict["sender"] as? String,
                  let messageBody = messageDict["messageBody"] as? String else {
                return nil
            }
            return Message(sender: sender, messageBody: messageBody)
        }
    }
    
    private func setupRealtimeListener() async {
        messagesChannel = supabase.channel("messages-listener")
        
        let changeStream = messagesChannel?.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "messages"
        )
        
        await messagesChannel?.subscribe()
        
        listenerTask = Task { [weak self] in
            guard let changeStream = changeStream else { return }
            
            for await change in changeStream {
                if case .insert(let action) = change {
                    await self?.handleNewMessage(from: action)
                }
            }
        }
    }
    
    private func handleNewMessage(from action: InsertAction) async {
        guard let senderJSON = action.record["sender"],
              let sender = senderJSON.stringValue,
              let messageBodyJSON = action.record["messageBody"],
              let messageBody = messageBodyJSON.stringValue else {
            return
        }
        
        await MainActor.run { [weak self] in
            guard let self = self else { return }
            let newMessage = Message(sender: sender, messageBody: messageBody)
            self.messages.append(newMessage)
            self.tableView.reloadData()
            self.scrollToBottom()
        }
    }
    
    private func scrollToBottom() {
        if messages.count > 0 {
            let indexPath = IndexPath(row: messages.count - 1, section: 0)
            tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        }
    }
    
    // MARK: - Actions
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
            as? NSValue)?.cgRectValue {
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
                as? Double ?? 0.3
        
            
            UIView.animate(withDuration: duration) {
                if let window = self.getKeyWindow() {
                    let bottomSafeAreaInset = window.safeAreaInsets.bottom
                    self.floatingInputView.transform = CGAffineTransform(
                        translationX: 0,
                        y: -(keyboardSize.height - bottomSafeAreaInset)
                    )
                    
                    let bottomInset = keyboardSize.height
                    self.tableView.contentInset.bottom = bottomInset - bottomSafeAreaInset
                    self.tableView.verticalScrollIndicatorInsets.bottom = bottomInset - bottomSafeAreaInset
                }
            }
            
            scrollToBottom()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
            as? Double ?? 0.3
        
        UIView.animate(withDuration: duration) {
            self.floatingInputView.transform = .identity
        }
        
        tableView.contentInset.bottom = originalTableViewBottomInset
        tableView.verticalScrollIndicatorInsets.bottom = originalTableViewBottomInset
    }
    
    @IBAction private func sendPressed(_ sender: UIButton) {
        Task { await sendMessage() }
    }
    
    @IBAction private func logOutPressed(_ sender: UIBarButtonItem) {
        Task {
            do {
                let channel = supabase.channel("messages-listener")
                try await supabase.auth.signOut()
                await supabase.removeChannel(channel)
                
                DispatchQueue.main.async {
                    self.floatingInputView.isHidden = true
                }
                
                navigationController?.popToRootViewController(animated: true)
            } catch {
                print("Error registering: \(error)")
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell
        cell.label.text = message.messageBody
        
        if message.sender == currentUserEmail {
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColours.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColours.purple)
        } else {
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColours.purple)
            cell.label.textColor = UIColor(named: K.BrandColours.lightPurple)
        }
        
        return cell
    }
}

// MARK: - FloatingInputViewDelegate
extension ChatViewController: FloatingInputViewDelegate {
    func didTapSendButton(with text: String) {
        Task { await sendMessage() }
    }
}
