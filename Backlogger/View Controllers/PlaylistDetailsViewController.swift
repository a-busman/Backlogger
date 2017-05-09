//
//  NewPlaylistViewController.swift
//  Backlogger
//
//  Created by Alex Busman on 5/4/17.
//  Copyright © 2017 Alex Busman. All rights reserved.
//

import UIKit

class PlaylistDetailsViewController: UITableViewController, UITextViewDelegate {

    let cellReuseIdentifier = "playlist_detail_cell"
    var playlistTitleView = PlaylistTitleView()
    var playlistDescriptionView = PlaylistDescriptionView()
    
    var titleTextViewHeight: CGFloat = 0.0
    var descriptionTextViewHeight: CGFloat = 0.0
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = .white
        self.tableView.estimatedRowHeight = 55.0
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.playlistTitleView.titleDelegate = self
        self.playlistTitleView.observer = self
        self.playlistDescriptionView.descriptionDelegate = self
        self.playlistDescriptionView.observer = self
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        playlistTitleView.titleTextView.removeObserver(self, forKeyPath: "contentSize")
        playlistDescriptionView.descriptionTextView.removeObserver(self, forKeyPath: "contentSize")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func cancelTapped(sender: UIBarButtonItem) {
        playlistTitleView.titleTextView.resignFirstResponder()
        playlistDescriptionView.descriptionTextView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneTapped(sender: UIBarButtonItem) {
        playlistTitleView.titleTextView.resignFirstResponder()
        playlistDescriptionView.descriptionTextView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! TableViewCell
        var cellView = UIView()
        if indexPath.row == 0 {
            cellView = self.playlistTitleView.view
        } else if indexPath.row == 1 {
            cellView = self.playlistDescriptionView.view
        }
        if indexPath.row == 0 || indexPath.row == 1 {
            cell.selectionStyle = .none


            cellView.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(cellView)
            
            NSLayoutConstraint(item: cellView,
                               attribute: .leading,
                               relatedBy: .equal,
                               toItem: cell.contentView,
                               attribute: .leading,
                               multiplier: 1.0,
                               constant: 0.0
                ).isActive = true
            NSLayoutConstraint(item: cellView,
                               attribute: .trailing,
                               relatedBy: .equal,
                               toItem: cell.contentView,
                               attribute: .trailing,
                               multiplier: 1.0,
                               constant: 0.0
                ).isActive = true
            NSLayoutConstraint(item: cellView,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: cell.contentView,
                               attribute: .top,
                               multiplier: 1.0,
                               constant: 0.0
                ).isActive = true
            NSLayoutConstraint(item: cellView,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: cell.contentView,
                               attribute: .bottom,
                               multiplier: 1.0,
                               constant: 0.0
                ).isActive = true
        }
        return cell
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            if let changeDict = change {
                if let newContentSize = (changeDict[NSKeyValueChangeKey.newKey] as AnyObject).cgSizeValue {
                    self.textView(object as? UITextView, sizeDidChange: newContentSize)
                }
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            if self.titleTextViewHeight < 150.0 {
                return 150.0
            } else {
                return self.titleTextViewHeight
            }
        } else if indexPath.row == 1 {
            if (self.descriptionTextViewHeight + 10) < 75.0 {
                return 75.0
            } else {
                return self.descriptionTextViewHeight + 10
            }
        } else {
            return 55.0
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func textView(_ textView: UITextView?, sizeDidChange size: CGSize) {
        if textView == self.playlistTitleView.titleTextView {
            self.titleTextViewHeight = size.height
        } else if textView == self.playlistDescriptionView.descriptionTextView {
            self.descriptionTextViewHeight = size.height
        }
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        if textView.textColor == .lightGray {
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
        }
        return true
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Combine the textView text and the replacement text to
        // create the updated text string
        let currentText = textView.text as NSString
        let updatedText = currentText.replacingCharacters(in: range, with: text)
        
        // If updated text view will be empty, add the placeholder
        // and set the cursor to the beginning of the text view
        if updatedText.isEmpty {
            if textView == self.playlistTitleView.titleTextView {
                textView.text = "Playlist Name"
            } else if textView == self.playlistDescriptionView.descriptionTextView {
                textView.text = "Description"
            }
            textView.textColor = UIColor.lightGray
            
            textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            
            return false
        }
            
            // Else if the text view's placeholder is showing and the
            // length of the replacement string is greater than 0, clear
            // the text view and set its color to black to prepare for
            // the user's entry
        else if textView.textColor == UIColor.lightGray && !text.isEmpty {
            textView.text = nil
            textView.textColor = UIColor.black
        }
        return true
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        if self.view.window != nil {
            if textView.textColor == UIColor.lightGray {
                textView.selectedTextRange = textView.textRange(from: textView.beginningOfDocument, to: textView.beginningOfDocument)
            }
        }
    }
}
