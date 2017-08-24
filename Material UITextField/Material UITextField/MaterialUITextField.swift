//
//  MaterialUITextField.swift
//  Material UITextField
//
//  Created by Yong Su on 4/18/16.
//  Copyright © 2016 Yong Su. All rights reserved.
//

import UIKit

extension String {
    func heightWithConstrainedWidth(_ width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        
        return boundingBox.height
    }
}

@IBDesignable class MaterialUITextField: UITextField {
    
    //
    //# MARK: - Variables
    //
    
    // Bottom border layer
    fileprivate var borderLayer: CAShapeLayer!
    // Top label layer
    fileprivate var labelLayer: CATextLayer!
    // Note icon layer
    fileprivate var noteIconLayer: CATextLayer!
    // Note text layer
    fileprivate var noteTextLayer: CATextLayer!
    // Note font size
    fileprivate var noteFontSize: CGFloat = 12.0
    // Cache secure text initial state
    fileprivate var isSecureText: Bool?
    // The button to toggle secure text entry
    fileprivate var secureToggler: UIButton!
    
    fileprivate enum icon: String {
        case openEye = "\u{f06e}"
        case closedEye = "\u{f070}"
    }
    
    // The color of the bottom border
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // The widht of the bottom border
    @IBInspectable var borderWidth: CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // The color of the label
    @IBInspectable var labelColor: UIColor = UIColor.clear {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // The color of note text
    @IBInspectable var noteTextColor: UIColor = UIColor.clear {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // The note text
    @IBInspectable var noteText: String? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // The color of note icon
    var noteIconColor: UIColor = UIColor.clear {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // The note icon
    var noteIcon: String? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override var isSecureTextEntry: Bool {
        set {
            super.isSecureTextEntry = newValue
            // Here we remember the initial secureTextEntry setting
            if isSecureText == nil && newValue {
                isSecureText = true
            }
        }
        get {
            return super.isSecureTextEntry
        }
    }
    
    //
    //# MARK: - Initialization
    //
    
    #if !TARGET_INTERFACE_BUILDER
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initRightView()
        registerNotifications()
    }
    #endif
    
    //
    // Cleanup the notification/event listeners when the view is about to dissapear
    //
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow == nil {
            NotificationCenter.default.removeObserver(self)
        } else {
            registerNotifications()
        }
    }
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(MaterialUITextField.onTextChanged), name: NSNotification.Name.UITextFieldTextDidChange, object: self)
    }
    
    func initRightView() {
        if isSecureText != nil {
            // Show the secure text toggler
            let togglerText: String = icon.closedEye.rawValue
            let togglerFont: UIFont = UIFont(name: "FontAwesome", size: 14.0)!
            let togglerTextSize = (togglerText as NSString).size(attributes: [NSFontAttributeName: togglerFont])
            
            secureToggler = UIButton(type: UIButtonType.custom)
            secureToggler.frame = CGRect(x: 0, y: 0, width: togglerTextSize.width, height: togglerTextSize.height)
            secureToggler.setTitle(togglerText, for: UIControlState())
            secureToggler.setTitleColor(UIColor.black, for: UIControlState())
            secureToggler.titleLabel?.font = togglerFont
            secureToggler.addTarget(self, action: #selector(MaterialUITextField.toggleSecureTextEntry), for: .touchUpInside)
            
            rightView = secureToggler
            rightViewMode = UITextFieldViewMode.always
        } else {
            // Show the clear button
            self.clearButtonMode = UITextFieldViewMode.whileEditing
        }
    }
    
    //
    // Add border layer as sub layer
    //
    func setupBorder() {
        if borderLayer == nil {
            borderLayer = CAShapeLayer()
            borderLayer.frame = layer.bounds
            layer.addSublayer(borderLayer)
        }
    }
    
    func setupLabel() {
        if labelLayer == nil && placeholder != nil {
            let labelSize = ((placeholder! as NSString)).size(attributes: [NSFontAttributeName: font!])
            
            labelLayer = CATextLayer()
            labelLayer.opacity = 0
            labelLayer.string = placeholder
            labelLayer.font = font
            labelLayer.fontSize = (font?.pointSize)!
            labelLayer.foregroundColor = labelColor.cgColor
            labelLayer.isWrapped = false
            labelLayer.alignmentMode = kCAAlignmentLeft
            labelLayer.contentsScale = UIScreen.main.scale
            labelLayer.frame = CGRect(x: 0, y: (layer.bounds.size.height - labelSize.height) / 2.0, width: labelSize.width, height: labelSize.height)
            
            layer.addSublayer(labelLayer)
        }
    }
    
    func setupNote() {
        if noteIconLayer == nil {
            noteIconLayer = CATextLayer()
            noteIconLayer.font = "FontAwesome" as CFTypeRef?
            noteIconLayer.fontSize = noteFontSize
            noteIconLayer.alignmentMode = kCAAlignmentLeft
            noteIconLayer.contentsScale = UIScreen.main.scale
            
            layer.addSublayer(noteIconLayer)
        }
        
        if noteTextLayer == nil {
            noteTextLayer = CATextLayer()
            noteTextLayer.font = font
            noteTextLayer.fontSize = noteFontSize
            noteTextLayer.isWrapped = true
            noteTextLayer.alignmentMode = kCAAlignmentLeft
            noteTextLayer.contentsScale = UIScreen.main.scale
            
            layer.addSublayer(noteTextLayer)
        }
    }
    
    //
    //# MARK: - Renderers
    //
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setupLayer()
    }
    
    func setupLayer() {
        layer.masksToBounds = false
        
        setupBorder()
        setupLabel()
        setupNote()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        drawBorder()
        drawLabel()
        drawNote()
    }
    
    //
    // Redraw the border
    //
    func drawBorder() {
        if borderLayer != nil {
            let size = layer.frame.size
            let path = UIBezierPath()
            
            path.move(to: CGPoint(x: 0, y: size.height))
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.close()
            
            borderLayer.lineWidth = borderWidth
            borderLayer.strokeColor = borderColor.cgColor
            borderLayer.path = path.cgPath
        }
    }
    
    //
    // Redraw the label
    //
    func drawLabel() {
        if labelLayer != nil {
            labelLayer.foregroundColor = labelColor.cgColor
        }
    }
    
    //
    // Redraw the note
    //
    func drawNote() {
        var startX:CGFloat = 0.0
        
        if noteIconLayer != nil {
            let noteIconFont: UIFont = UIFont(name: "FontAwesome", size: noteFontSize)!
            let noteIconSize = ((noteIcon ?? "") as NSString).size(attributes: [NSFontAttributeName: noteIconFont])
            
            noteIconLayer.string = noteIcon
            noteIconLayer.foregroundColor = noteIconColor.cgColor
            noteIconLayer.frame = CGRect(x: 0, y: layer.bounds.size.height + 5.0, width: noteIconSize.width, height: noteIconSize.height)
            
            if noteIcon != nil {
                startX = noteIconSize.width + 5.0
            }
        }
        
        if noteTextLayer != nil {
            let noteWidth = layer.bounds.size.width - startX
            let noteHeight = (noteText ?? "").heightWithConstrainedWidth(noteWidth, font: UIFont(name: (font?.fontName)!, size: noteFontSize)!)
            
            noteTextLayer.string = noteText
            noteTextLayer.foregroundColor = noteTextColor.cgColor
            noteTextLayer.frame = CGRect(x: startX, y: layer.bounds.size.height + 2.0, width: noteWidth, height: noteHeight)
        }
    }
    
    //
    //# MARK: - Event handlers
    //
    
    func toggleSecureTextEntry() {
        // Resign and restore the first responder
        // solves the font issue
        resignFirstResponder()
        isSecureTextEntry = !isSecureTextEntry
        becomeFirstResponder()
        
        secureToggler.setTitle(isSecureTextEntry ? icon.closedEye.rawValue : icon.openEye.rawValue, for: UIControlState())
        
        // A trick to reset the cursor position after toggle secureTextEntry
        let temp = text
        text = nil
        text = temp
    }
    
    //
    // Apply animations when editing text
    //
    func onTextChanged() {
        if placeholder == nil || labelLayer == nil {
            return
        }
        
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        let positionAnimation = CABasicAnimation(keyPath: "position.y")
        
        if text?.characters.count == 0 {
            // Move the label back
            opacityAnimation.toValue = 0
            let labelSize = ((placeholder! as NSString)).size(attributes: [NSFontAttributeName: font!])
            positionAnimation.toValue = (layer.bounds.size.height - labelSize.height) / 2.0
        } else {
            // Move up the label
            opacityAnimation.toValue = 1
            let labelSize = ((placeholder! as NSString)).size(attributes: [NSFontAttributeName: font!])
            positionAnimation.toValue = -labelSize.height
        }
        
        let group = CAAnimationGroup()
        group.animations = [opacityAnimation, positionAnimation]
        group.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        group.isRemovedOnCompletion = false
        group.fillMode = kCAFillModeForwards
        group.duration = 0.2
        
        labelLayer.add(group, forKey: nil)
    }
    
}
