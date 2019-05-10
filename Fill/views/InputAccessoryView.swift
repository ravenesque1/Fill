//
//  InputAccessoryView.swift
//  Fill
//
//  Created by Raven Weitzel on 5/9/19.
//  Copyright © 2019 Raven Weitzel. All rights reserved.
//

import UIKit

class InputAccessoryView: UIView {

    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!

    var nextAction: (() -> ())?
    var doneAction: (() -> ())?

    @IBAction func nextAction(_ sender: UIButton) {
        nextAction?()
    }

    @IBAction func doneAction(_ sender: UIButton) {
        doneAction?()
    }

    static func instance(next: (() -> ())?, done: (() -> ())?) -> InputAccessoryView {
        let view = Bundle.main.loadNibNamed("InputAccessoryView", owner: self, options: nil)!.first as! InputAccessoryView

        view.nextAction = next
        view.doneAction = done

        return view
    }
}
