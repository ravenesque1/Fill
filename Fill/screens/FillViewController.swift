//
//  FillViewController.swift
//  Fill
//
//  Created by Raven Weitzel on 5/8/19.
//  Copyright © 2019 Raven Weitzel. All rights reserved.
//

import UIKit

class FillViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!

    //left bucket
    @IBOutlet weak var firstBucketContainer: UIView!
    @IBOutlet weak var firstBucket: UIView!
    @IBOutlet weak var firstBucketWaterHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var firstTextField: UITextField!
    @IBOutlet weak var firstBucketLabel: UILabel!

    //right bucket
    @IBOutlet weak var secondBucketContainer: UIView!
    @IBOutlet weak var secondBucket: UIView!
    @IBOutlet weak var secondBucketWaterHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var secondTextField: UITextField!
    @IBOutlet weak var secondBucketLabel: UILabel!

    //other
    @IBOutlet weak var bucketsHeightRatio: NSLayoutConstraint!
    @IBOutlet weak var thirdTextField: UITextField!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var solutionLabel: UILabel!
    var animations: [DispatchWorkItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }
}

//MARK: - Actions

extension FillViewController {

    @IBAction func pourAction(_ sender: Any) {
        attemptPour()
    }

    @IBAction func resetAction(_ sender: Any) {

        self.view.endEditing(true)
        self.view.subviews.forEach({$0.layer.removeAllAnimations()})
        self.view.layer.removeAllAnimations()
        self.view.layoutIfNeeded()
        animations.forEach { $0.cancel() }

        firstTextField.text = "4"
        secondTextField.text = "2"
        thirdTextField.text = "3"

        resetBuckets()
    }

    @objc func keyboardWillShow(notification: NSNotification) {

        //Need to calculate keyboard exact size due to Apple suggestions
        self.scrollView.isScrollEnabled = true
        var info = notification.userInfo!
        let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize!.height, right: 0.0)

        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets

        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height

        if (!aRect.contains(resetButton.frame.origin)){
            self.scrollView.scrollRectToVisible(resetButton.frame, animated: true)
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        //Once keyboard disappears, restore original positions
        var info = notification.userInfo!
        let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: -keyboardSize!.height, right: 0.0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        self.view.endEditing(true)
        self.scrollView.isScrollEnabled = false
    }
}

//MARK: - UI

extension FillViewController {

    private func configureView() {

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        firstTextField.inputAccessoryView = InputAccessoryView.instance(next: {
            self.secondTextField.becomeFirstResponder()
        }, done: {
            self.view.endEditing(true)
        })

        secondTextField.inputAccessoryView = InputAccessoryView.instance(next: {
            self.thirdTextField.becomeFirstResponder()
        }, done: {
            self.view.endEditing(true)
        })

        thirdTextField.inputAccessoryView = InputAccessoryView.instance(next: nil, done: {
            self.view.endEditing(true)
            self.attemptPour()
        })

        (thirdTextField.inputAccessoryView as? InputAccessoryView)?.nextButton.isHidden = true


        for container in [firstBucketContainer, secondBucketContainer] {
            container?.borders(for: [.left, .bottom, .right], width: 2)
        }

        resetBuckets()
    }

    private func attemptPour() {
        self.view.endEditing(true)

        resetBuckets()

        //do nothing if input invalid
        guard let firstM = firstTextField.text,
            let secondM = secondTextField.text,
            let thirdM = thirdTextField.text,
            var firstMax = Int(firstM),
            var secondMax = Int(secondM),
            let goal = Int(thirdM) else {
                return
        }

        let result = minSteps(firstMax, secondMax, goal)

        //do nothing if input has no solution
        guard result.0[0].0 != -1 else {
            solutionLabel.text = "No Solution"
            return
        }

        let steps = result.0

        //update solutions label
        let descriptor = steps.count == 1 ? "step" : "steps"
        solutionLabel.text = "Solution found in \(steps.count) \(descriptor)"

        //match swapping done in pour
        let gotSwapped = result.1
        if gotSwapped {
            swap(&firstMax, &secondMax)
        }

        //set bucket sizes
        let constant = (secondBucketContainer.frame.height - (secondBucketContainer.frame.height * CGFloat(firstMax) / CGFloat(secondMax))) * -1
        bucketsHeightRatio.constant =  constant

        //animate all changes, then start pouring
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in

            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.performPour(firstMax: firstMax,
                                 secondMax: secondMax,
                                 goal: goal,
                                 steps: steps)
            }
        })
    }

    private func performPour(firstMax: Int,
                             secondMax: Int,
                             goal: Int,
                             steps: [(Int, Int)]) {
        for (idx, item) in steps.enumerated() {

            let prevDelay = idx - 1 <= 0 ? 0 : Double(idx)
            let delay = Double(idx == 0 ? 0 : idx + 1) + prevDelay

            let task = DispatchWorkItem {
                let height1 = CGFloat(item.0) / CGFloat(firstMax) * self.firstBucketContainer.frame.height
                let height2 = CGFloat(item.1) / CGFloat(secondMax) * self.secondBucketContainer.frame.height

                self.firstBucketWaterHeightConstraint.constant = height1
                self.secondBucketWaterHeightConstraint.constant = height2

                let firstLabel = "contents: \(item.0)/\(firstMax) gal of water"
                let secondLabel = "contents: \(item.1)/\(secondMax) gal of water"

                self.firstBucketLabel.text = firstLabel
                self.secondBucketLabel.text = secondLabel



                UIView.animate(withDuration: 0.5, animations: {
                    self.view.layoutIfNeeded()

                }, completion: { _ in
                    if let last = steps.last, last == item {
                        let bucketToColor = item.0 == goal ? self.firstBucket : self.secondBucket
                        bucketToColor?.backgroundColor = .green

                    }
                })
            }

            animations += [task]
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: task)
        }
    }

    private func resetBuckets() {
        for constraint in [firstBucketWaterHeightConstraint, secondBucketWaterHeightConstraint] {
            constraint?.constant = 0
        }

        bucketsHeightRatio.constant = 0

        [firstBucket, secondBucket].forEach { $0?.backgroundColor = .blue }

        let firstLabel = "contents: 0 gal of water"
        let secondLabel = "contents: 0 gal of water"

        firstBucketLabel.text = firstLabel
        secondBucketLabel.text = secondLabel

        solutionLabel.text = nil
    }
}


//MARK: - Water Jug Algorithm

extension FillViewController {


    ///Performs a depth-first search
    func pour(_ fromMax: Int, _ toMax: Int, _ goal: Int) -> [(Int, Int)] {
        var result: [(Int, Int)] = []

        var from = fromMax
        var to = 0

        result += [(from, to)]

        while (from != goal) && (to != goal) {
            let pourableAmt = min(from, toMax - to)

            to += pourableAmt
            from -= pourableAmt

            result += [(from, to)]

            if (from == goal) || (to == goal) {
                break
            }

            if from == 0 {
                from = fromMax
                result += [(from, to)]
            }

            if to == toMax {
                to = 0
                result += [(from, to)]
            }
        }

        return result
    }

    ///Assumes a goal larger than both capacities is impossible
    ///Enforces size order
    ///Chooses best option out of 2 (always pouring into a or b)
    func minSteps(_ aCapacity: Int, _ bCapacity: Int, _ goal: Int) -> ([(Int, Int)], Bool) {

        var gotSwapped = false

        var smaller = aCapacity
        var larger = bCapacity

        if smaller > larger {
            swap(&smaller, &larger)
            gotSwapped = true
        }

        if goal > larger {
            return ([(-1, -1)], false)
        }

        if (goal % gcd(smaller, larger) != 0) {
            return ([(-1, -1)], false)
        }

        let option1 = pour(smaller, larger, goal)

        let option2Unswapped = pour(larger, smaller, goal)
        let option2 = option2Unswapped.map { (tuple: (Int, Int)) -> (Int, Int) in
            return (tuple.1, tuple.0)
        }

        let result = option2.count < option1.count ? option2 : option1

        return (result, gotSwapped)
    }

    private func swapTuple(_ tuple: inout (Int, Int)) {
        let first = tuple.0
        let second = tuple.1

        tuple.0 = second
        tuple.1 = first
    }

    private func gcd(_ a: Int, _ b: Int) -> Int {
        guard b != 0 else {
            return a
        }

        return gcd(b, a%b)
    }
}
