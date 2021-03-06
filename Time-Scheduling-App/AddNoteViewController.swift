//
//  AddNoteViewController.swift
//  Time-Scheduling-App
//
//  Created by Kristie Huang on 7/18/17.
//  Copyright © 2017 Kristie Huang. All rights reserved.
//

import Foundation
import UIKit
import FirebaseDatabase

class AddNoteViewController: UIViewController {
    
    static var event: Event?
    
    @IBOutlet weak var eventNameLabel: UILabel!
    
    @IBAction func unwindToAddNote(_ segue: UIStoryboardSegue) {
    }
    
    @IBAction func finishButtonTapped(_ sender: Any) {
        
        if noteTextView.text.isEmpty {
            noteTextView.text = ""
        }
        
        let ref = Database.database().reference()
        
        let key = AddNoteViewController.event?.key
        print(key!)
        
        let noteData = ["events/\(User.current.uid)/\(key!)/note": noteTextView.text, "users/\(User.current.uid)/hosting events/\(key!)/note": noteTextView.text]
        //not updated to invited user > invited events> notes
        
        ref.updateChildValues(noteData) { (error, _) in
            if let error = error {
                assertionFailure(error.localizedDescription)
            }
        }
    }
    
    @IBOutlet weak var noteTextView: UITextView!
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        noteTextView.delegate = self as UITextViewDelegate
        print(AddNoteViewController.event?.name!)
        eventNameLabel.text = AddNoteViewController.event?.name
        noteTextView.text = AddNoteViewController.event?.note

        //dismiss keyboard
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    
}
extension AddNoteViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let maxChar: Int = 100
        return (textView.text.utf16.count) + text.utf16.count - range.length <= maxChar

    }
}
