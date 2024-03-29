import Foundation
import RealmSwift
import UIKit

class RedactInfoViewController: UIViewController {
    
    //MARK: - Properties
    var task: Task?
    private var textView: UITextView!
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureTextViewContent()
        setTextViewConstraints()
    }
    
    //MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Сохранить", style: .done, target: self, action: #selector(saveChanges))
    }
    
    private func configureTextViewContent() {
        textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.isEditable = true
        textView.delegate = self
        view.addSubview(textView)
        
        if let task = task {
            setupTextViewAttributedText(with: task)
        }
        
        recognizeHashtags(in: textView)
    }
    
    private func setupTextViewAttributedText(with task: Task) {
        
        let boldFont = UIFont.boldSystemFont(ofSize: 22)
        let regularFont = UIFont.systemFont(ofSize: 16)
        
        let nameAttributes: [NSAttributedString.Key: Any] = [.font: boldFont]
        let nameAttributedString = NSMutableAttributedString(string: task.name, attributes: nameAttributes)
        
        let noteAttributes: [NSAttributedString.Key: Any] = [.font: regularFont]
        let noteAttributedString = NSAttributedString(string: "\n" + task.note, attributes: noteAttributes)
        
        nameAttributedString.append(noteAttributedString)
        
        textView.attributedText = nameAttributedString
    }
    
    private func setTextViewConstraints() {
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    // MARK: - Hashtag Recognition
    func recognizeHashtags(in textView: UITextView) {
        guard let attributedText = textView.attributedText else { return }
        let text = attributedText.string
        let attributedString = NSMutableAttributedString(attributedString: attributedText)

        let hashtagPattern = "#\\w+"
        let regex = try? NSRegularExpression(pattern: hashtagPattern, options: [])
        
        let matches = regex?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? []
        
        for match in matches {
            let matchRange = match.range
            if let swiftRange = Range(matchRange, in: text) {
                let hashtagValue = text[swiftRange]
                attributedString.addAttribute(.link, value: "hashtag://\(hashtagValue)", range: matchRange)
            }
        }
        
        textView.attributedText = attributedString
    }
    
    // MARK: - Save Changes
    @objc private func saveChanges() {
        guard let fullText = textView.text else { return }
        let components = fullText.components(separatedBy: "\n")
        guard !components.isEmpty else { return }
        
        let name = components[0]
        let note = components.dropFirst().joined(separator: "\n")
        
        do {
            let realm = try Realm()
            try realm.write {
                task?.name = name
                task?.note = note
            }
            navigationController?.popViewController(animated: true)
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}

// MARK: - UITextViewDelegate
extension RedactInfoViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.scheme == "hashtag" {
            print("Hashtag scheme recognized")
            let hashtag = URL.absoluteString.replacingOccurrences(of: "hashtag://#", with: "")
            print("Processed hashtag: \(hashtag)")
            showNotes(withHashtag: hashtag)
            return false
        }
        return true
    }
    
    func showNotes(withHashtag hashtag: String) {
        print(hashtag)
    }
}
