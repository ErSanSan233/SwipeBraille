//
//  KeyboardViewController.swift
//  Braille
//
//  Created on 2025/1/7.
//

import UIKit

class KeyboardViewController: UIInputViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
    
    // 布局常量
    private let keyboardHeight: CGFloat = 250
    private let dotSize: CGFloat = 45  // 圆形按钮的大小
    private let dotSpacing: CGFloat = 15  // 按钮之间的间距
    private let functionKeyWidth: CGFloat = 50  // 功能键的宽度
    private let functionKeyHeight: CGFloat = 45  // 与圆形按钮等高
    
    // 添加颜色常量
    private let keyboardBackgroundColor: UIColor = {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 28/255, green: 28/255, blue: 30/255, alpha: 1.0)
            default:
                return UIColor(red: 209/255, green: 212/255, blue: 217/255, alpha: 1.0)
            }
        }
    }()
    
    private let buttonBackgroundColor: UIColor = {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 44/255, green: 44/255, blue: 46/255, alpha: 1.0)
            default:
                return .white
            }
        }
    }()
    
    private let buttonHighlightColor: UIColor = {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor.systemBlue.withAlphaComponent(0.7)
            default:
                return .systemBlue
            }
        }
    }()
    
    private let buttonPressedColor: UIColor = {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(red: 58/255, green: 58/255, blue: 60/255, alpha: 1.0)
            default:
                return UIColor.systemGray6
            }
        }
    }()
    
    // UI 组件
    private var dotButtons: [UIButton] = []
    private var deleteButton: UIButton!
    private var containerView: UIView!
    private var pathLayer: CAShapeLayer?
    private var enterButton: UIButton!
    private var spaceButton: UIButton!
    private var emptyButton: UIButton!
    
    // 手势状态
    private var isTracking: Bool = false
    private var isPanning: Bool = false
    private var touchedDots: Set<Int> = []
    private var currentPath: UIBezierPath?
    private var touchedPoints: [CGPoint] = []
    
    // 点位映射
    private let dotMapping: [Int: Int] = [
        1: 3, 2: 6,  // 第一行
        3: 1, 4: 4,  // 第二行
        5: 2, 6: 5,  // 第三行
        7: 3, 8: 6   // 第四行（映射到第一行）
    ]
    
    // 盲文映射
    private var brailleMap: [String: String] = [:]
    
    // 定时器
    private var deleteTimer: Timer?
    private let initialDeleteDelay: TimeInterval = 0.5  // 开始连续删除前的延迟
    private let continuousDeleteInterval: TimeInterval = 0.1  // 连续删除的间隔
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboard()
        setupGestureRecognizer()
        loadBrailleMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupKeyboardHeight()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopContinuousDelete()
    }
    
    // MARK: - Setup Methods
    
    private func setupKeyboardHeight() {
        if let inputView = view as? UIInputView {
            inputView.allowsSelfSizing = true
            let heightConstraint = NSLayoutConstraint(
                item: view!,
                attribute: .height,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: keyboardHeight
            )
            heightConstraint.priority = .required
            view.addConstraint(heightConstraint)
        }
    }
    
    private func setupKeyboard() {
        view.backgroundColor = keyboardBackgroundColor
        setupDotButtons()
        setupDeleteButton()
        setupEnterButton()
        setupSpaceButton()
        setupEmptyButton()  // 添加空方键
        setupPathLayer()
    }
    
    private func setupDotButtons() {
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        setupContainerViewConstraints()
        createDotButtons()
    }
    
    private func setupContainerViewConstraints() {
        // 获取退格键的大小和位置参考
        let deleteButtonSize: CGFloat = 40
        let bottomPadding: CGFloat = 10
        
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            // 不再使用centerY，改用bottom对齐
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomPadding),
            containerView.widthAnchor.constraint(equalToConstant: dotSize * 2 + dotSpacing),
            containerView.heightAnchor.constraint(equalToConstant: dotSize * 4 + dotSpacing * 3)
        ])
    }
    
    private func createDotButtons() {
        for i in 0..<8 {
            let button = createDotButton(tag: i + 1)
            dotButtons.append(button)
            containerView.addSubview(button)
            
            let column = i % 2
            let row = i / 2
            
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: dotSize),
                button.heightAnchor.constraint(equalToConstant: dotSize),
                button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: CGFloat(column) * (dotSize + dotSpacing)),
                button.topAnchor.constraint(equalTo: containerView.topAnchor, constant: CGFloat(row) * (dotSize + dotSpacing))
            ])
        }
    }
    
    private func createDotButton(tag: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tag = tag
        
        setupDotButtonAppearance(button)
        setupDotButtonLabel(button, tag: tag)
        
        return button
    }
    
    private func setupDotButtonAppearance(_ button: UIButton) {
        button.backgroundColor = buttonBackgroundColor
        button.layer.cornerRadius = dotSize / 2
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.3 : 0.1
        button.layer.shadowRadius = 0
        
        // 修改第一行按钮的透明度为 0.35
        if button.tag == 1 || button.tag == 2 {
            button.alpha = 0.35
        }
    }
    
    private func setupDotButtonLabel(_ button: UIButton, tag: Int) {
        let actualDot = dotMapping[tag] ?? tag
        button.setTitle("\(actualDot)", for: .normal)
        button.setTitleColor(.systemGray2, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
    }
    
    private func setupDeleteButton() {
        deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        setupDeleteButtonAppearance()
        setupDeleteButtonActions()
        setupDeleteButtonConstraints()
    }
    
    private func setupDeleteButtonAppearance() {
        deleteButton.setImage(UIImage(systemName: "delete.left"), for: .normal)
        deleteButton.backgroundColor = buttonBackgroundColor
        deleteButton.layer.cornerRadius = 8
        deleteButton.layer.shadowColor = UIColor.black.cgColor
        deleteButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        deleteButton.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.3 : 0.1
        deleteButton.layer.shadowRadius = 0
        deleteButton.tintColor = .systemGray
        
        view.addSubview(deleteButton)
    }
    
    private func setupDeleteButtonActions() {
        // 移除原有的触摸事件
        deleteButton.removeTarget(self, action: nil, for: .allEvents)
        
        // 添加新的触摸事件
        deleteButton.addTarget(self, action: #selector(handleDeleteTouchDown), for: .touchDown)
        deleteButton.addTarget(self, action: #selector(handleDeleteTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    private func setupDeleteButtonConstraints() {
        NSLayoutConstraint.activate([
            deleteButton.widthAnchor.constraint(equalToConstant: functionKeyWidth),
            deleteButton.heightAnchor.constraint(equalToConstant: functionKeyHeight),
            deleteButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            // 与第一行对齐
            deleteButton.centerYAnchor.constraint(equalTo: dotButtons[0].centerYAnchor)
        ])
    }
    
    private func setupEnterButton() {
        enterButton = UIButton(type: .system)
        enterButton.translatesAutoresizingMaskIntoConstraints = false
        
        setupEnterButtonAppearance()
        setupEnterButtonActions()
        setupEnterButtonConstraints()
    }
    
    private func setupEnterButtonAppearance() {
        enterButton.setImage(UIImage(systemName: "return"), for: .normal)
        enterButton.backgroundColor = buttonBackgroundColor
        enterButton.layer.cornerRadius = 8
        enterButton.layer.shadowColor = UIColor.black.cgColor
        enterButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        enterButton.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.3 : 0.1
        enterButton.layer.shadowRadius = 0
        enterButton.tintColor = .systemGray
        
        view.addSubview(enterButton)
    }
    
    private func setupEnterButtonActions() {
        enterButton.addTarget(self, action: #selector(handleEnterTouchDown), for: .touchDown)
        enterButton.addTarget(self, action: #selector(handleEnterTouchUp), for: [.touchUpInside, .touchUpOutside])
        enterButton.addTarget(self, action: #selector(handleEnter), for: .touchUpInside)
    }
    
    private func setupEnterButtonConstraints() {
        NSLayoutConstraint.activate([
            enterButton.widthAnchor.constraint(equalToConstant: functionKeyWidth),
            enterButton.heightAnchor.constraint(equalToConstant: functionKeyHeight),
            enterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            // 与第二行对齐
            enterButton.centerYAnchor.constraint(equalTo: dotButtons[2].centerYAnchor)
        ])
    }
    
    private func setupSpaceButton() {
        spaceButton = UIButton(type: .system)
        spaceButton.translatesAutoresizingMaskIntoConstraints = false
        
        setupSpaceButtonAppearance()
        setupSpaceButtonActions()
        setupSpaceButtonConstraints()
    }
    
    private func setupSpaceButtonAppearance() {
        spaceButton.setTitle("空格", for: .normal)
        spaceButton.backgroundColor = buttonBackgroundColor
        spaceButton.layer.cornerRadius = 8
        spaceButton.layer.shadowColor = UIColor.black.cgColor
        spaceButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        spaceButton.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.3 : 0.1
        spaceButton.layer.shadowRadius = 0
        spaceButton.tintColor = .systemGray
        
        view.addSubview(spaceButton)
    }
    
    private func setupSpaceButtonActions() {
        spaceButton.addTarget(self, action: #selector(handleSpaceTouchDown), for: .touchDown)
        spaceButton.addTarget(self, action: #selector(handleSpaceTouchUp), for: [.touchUpInside, .touchUpOutside])
        spaceButton.addTarget(self, action: #selector(handleSpace), for: .touchUpInside)
    }
    
    private func setupSpaceButtonConstraints() {
        NSLayoutConstraint.activate([
            spaceButton.widthAnchor.constraint(equalToConstant: functionKeyWidth),
            spaceButton.heightAnchor.constraint(equalToConstant: functionKeyHeight),
            spaceButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            // 与第三行对齐
            spaceButton.centerYAnchor.constraint(equalTo: dotButtons[4].centerYAnchor)
        ])
    }
    
    private func setupEmptyButton() {
        emptyButton = UIButton(type: .system)
        emptyButton.translatesAutoresizingMaskIntoConstraints = false
        
        // 设置胶囊形状和外观
        emptyButton.backgroundColor = buttonBackgroundColor
        emptyButton.layer.cornerRadius = functionKeyHeight / 2  // 使用高度的一半作为圆角，形成胶囊形状
        emptyButton.layer.shadowColor = UIColor.black.cgColor
        emptyButton.layer.shadowOffset = CGSize(width: 0, height: 1)
        emptyButton.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.3 : 0.1
        emptyButton.layer.shadowRadius = 0
        
        // 设置标题
        emptyButton.setTitle("空方", for: .normal)
        emptyButton.setTitleColor(.systemGray, for: .normal)
        emptyButton.titleLabel?.font = .systemFont(ofSize: 15)
        
        // 添加触摸事件
        emptyButton.addTarget(self, action: #selector(handleEmptyTouchDown), for: .touchDown)
        emptyButton.addTarget(self, action: #selector(handleEmptyTouchUp), for: [.touchUpInside, .touchUpOutside])
        emptyButton.addTarget(self, action: #selector(handleEmpty), for: .touchUpInside)
        
        view.addSubview(emptyButton)
        
        NSLayoutConstraint.activate([
            emptyButton.widthAnchor.constraint(equalToConstant: functionKeyWidth),
            emptyButton.heightAnchor.constraint(equalToConstant: functionKeyHeight),
            emptyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            emptyButton.centerYAnchor.constraint(equalTo: dotButtons[6].centerYAnchor)
        ])
    }
    
    private func setupPathLayer() {
        let pathLayer = CAShapeLayer()
        pathLayer.fillColor = nil
        pathLayer.strokeColor = UIColor.systemBlue.withAlphaComponent(0.5).cgColor
        pathLayer.lineWidth = 4
        pathLayer.lineCap = .round
        pathLayer.lineJoin = .round
        containerView.layer.addSublayer(pathLayer)
        self.pathLayer = pathLayer
    }
    
    // MARK: - Gesture Handling
    
    private func setupGestureRecognizer() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        let touchGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleTouchGesture(_:)))
        touchGesture.minimumPressDuration = 0
        touchGesture.delegate = self
        view.addGestureRecognizer(touchGesture)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let location = touch.location(in: view)
        return !deleteButton.frame.contains(location) &&
               !enterButton.frame.contains(location) &&
               !spaceButton.frame.contains(location) &&
               !emptyButton.frame.contains(location)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: - Touch Handling
    
    @objc private func handleTouchGesture(_ gesture: UILongPressGestureRecognizer) {
        let locationInView = gesture.location(in: view)
        
        switch gesture.state {
        case .began:
            startNewGesture(at: locationInView)
        case .changed:
            break  // 由 pan 手势处理移动
        case .ended, .cancelled:
            if !isPanning {
                handleGestureEnded()
            }
        default:
            break
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        isPanning = true
        let locationInView = gesture.location(in: view)
        let location = view.convert(locationInView, to: containerView)
        
        switch gesture.state {
        case .began:
            if !isTracking {
                startNewGesture(at: locationInView)
            }
        case .changed:
            updateGesture(at: locationInView, containerLocation: location)
        case .ended, .cancelled:
            isPanning = false
            handleGestureEnded()
        default:
            break
        }
    }
    
    private func startNewGesture(at location: CGPoint) {
        isTracking = true
        touchedDots.removeAll()
        checkAndActivateDotAt(location)
        
        let containerLocation = view.convert(location, to: containerView)
        currentPath = UIBezierPath()
        currentPath?.move(to: containerLocation)
        touchedPoints = [containerLocation]
        updatePathLayer()
    }
    
    private func updateGesture(at location: CGPoint, containerLocation: CGPoint) {
        guard isTracking else { return }
        
        currentPath?.addLine(to: containerLocation)
        touchedPoints.append(containerLocation)
        checkAndActivateDotAt(location)
        updatePathLayer()
    }
    
    private func handleGestureEnded() {
        isTracking = false
        
        animatePathLayerDisappearance()
        handleInput()
        resetState()
    }
    
    // MARK: - Helper Methods
    
    private func animatePathLayerDisappearance() {
        UIView.animate(withDuration: 0.3) {
            self.pathLayer?.opacity = 0
        } completion: { _ in
            self.pathLayer?.path = nil
            self.pathLayer?.opacity = 1
        }
    }
    
    private func handleInput() {
        guard !touchedDots.isEmpty else { return }
        
        let pattern = createBinaryPattern()
        if let brailleChar = brailleMap[pattern] {
            textDocumentProxy.insertText(brailleChar)
        }
    }
    
    private func createBinaryPattern() -> String {
        var pattern = Array(repeating: "0", count: 6)
        for dot in touchedDots where dot >= 1 && dot <= 6 {
            pattern[dot - 1] = "1"
        }
        return pattern.joined()
    }
    
    private func resetState() {
        touchedDots.removeAll()
        currentPath = nil
        touchedPoints.removeAll()
        resetAllButtonsAppearance()
    }
    
    private func checkAndActivateDotAt(_ location: CGPoint) {
        for button in dotButtons {
            let buttonFrameInContainer = button.frame
            let buttonFrameInView = containerView.convert(buttonFrameInContainer, to: view)
            
            if buttonFrameInView.contains(location) {
                let buttonTag = button.tag
                if let actualDot = dotMapping[buttonTag], !touchedDots.contains(actualDot) {
                    touchedDots.insert(actualDot)
                    updateMappedButtonsAppearance(for: actualDot, isSelected: true)
                }
            }
        }
    }
    
    private func updateMappedButtonsAppearance(for dot: Int, isSelected: Bool) {
        for (buttonTag, mappedDot) in dotMapping {
            if mappedDot == dot {
                if let button = dotButtons.first(where: { $0.tag == buttonTag }) {
                    button.backgroundColor = isSelected ? buttonHighlightColor : buttonBackgroundColor
                    
                    // 修改第一行按钮的透明度为 0.35
                    if buttonTag == 1 || buttonTag == 2 {
                        button.alpha = 0.35
                    }
                }
            }
        }
    }
    
    private func resetAllButtonsAppearance() {
        dotButtons.forEach { button in
            button.backgroundColor = buttonBackgroundColor
            // 修改第一行按钮的透明度为 0.35
            if button.tag == 1 || button.tag == 2 {
                button.alpha = 0.35
            }
        }
    }
    
    private func updatePathLayer() {
        guard let path = currentPath else { return }
        pathLayer?.path = path.cgPath
    }
    
    // MARK: - Delete Button Actions
    
    @objc private func handleDeleteTouchDown() {
        // 视觉反馈
        UIView.animate(withDuration: 0.1) {
            self.deleteButton.backgroundColor = self.buttonPressedColor
        }
        
        // 立即删除一个字符
        textDocumentProxy.deleteBackward()
        
        // 设置定时器，在一段延迟后开始连续删除
        deleteTimer = Timer.scheduledTimer(withTimeInterval: initialDeleteDelay, repeats: false) { [weak self] _ in
            self?.startContinuousDelete()
        }
    }
    
    @objc private func handleDeleteTouchUp() {
        // 视觉反馈
        UIView.animate(withDuration: 0.1) {
            self.deleteButton.backgroundColor = self.buttonBackgroundColor
        }
        
        // 停止定时器
        stopContinuousDelete()
    }
    
    private func startContinuousDelete() {
        // 停止现有的定时器
        deleteTimer?.invalidate()
        
        // 创建新的定时器进行连续删除
        deleteTimer = Timer.scheduledTimer(withTimeInterval: continuousDeleteInterval, repeats: true) { [weak self] _ in
            self?.textDocumentProxy.deleteBackward()
        }
    }
    
    private func stopContinuousDelete() {
        deleteTimer?.invalidate()
        deleteTimer = nil
    }
    
    // MARK: - Braille Map Loading
    
    private func loadBrailleMap() {
        guard let path = Bundle.main.path(forResource: "braille_cursor", ofType: "csv") else {
            print("CSV file not found in bundle")
            return
        }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let rows = content.components(separatedBy: .newlines)
            
            for row in rows.dropFirst() {
                let columns = row.components(separatedBy: ",")
                if columns.count >= 2 {
                    let char = columns[0]
                    let pattern = columns[1]
                    if !char.isEmpty && pattern.count == 6 {
                        brailleMap[pattern] = char
                    }
                }
            }
        } catch {
            print("Error loading braille map: \(error)")
        }
    }
    
    // MARK: - Enter Button Actions
    
    @objc private func handleEnterTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.enterButton.backgroundColor = self.buttonPressedColor
        }
    }
    
    @objc private func handleEnterTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.enterButton.backgroundColor = self.buttonBackgroundColor
        }
    }
    
    @objc private func handleEnter() {
        textDocumentProxy.insertText("\n")
    }
    
    // MARK: - Space Button Actions
    
    @objc private func handleSpaceTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.spaceButton.backgroundColor = self.buttonPressedColor
        }
    }
    
    @objc private func handleSpaceTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.spaceButton.backgroundColor = self.buttonBackgroundColor
        }
    }
    
    @objc private func handleSpace() {
        textDocumentProxy.insertText(" ")
    }
    
    // 添加空方键的事件处理方法
    @objc private func handleEmptyTouchDown() {
        UIView.animate(withDuration: 0.1) {
            self.emptyButton.backgroundColor = self.buttonPressedColor
        }
    }
    
    @objc private func handleEmptyTouchUp() {
        UIView.animate(withDuration: 0.1) {
            self.emptyButton.backgroundColor = self.buttonBackgroundColor
        }
    }
    
    @objc private func handleEmpty() {
        textDocumentProxy.insertText("⠀")  // 插入空方字符
    }
    
    // 添加主题切换支持
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            // 更新所有按钮的外观
            dotButtons.forEach { button in
                if !touchedDots.contains(button.tag) {
                    button.backgroundColor = buttonBackgroundColor
                }
            }
            
            // 更新功能键的外观
            deleteButton.backgroundColor = buttonBackgroundColor
            enterButton.backgroundColor = buttonBackgroundColor
            spaceButton.backgroundColor = buttonBackgroundColor
            emptyButton.backgroundColor = buttonBackgroundColor
            
            // 更新阴影
            let shadowOpacity: Float = traitCollection.userInterfaceStyle == .dark ? 0.3 : 0.1
            dotButtons.forEach { $0.layer.shadowOpacity = shadowOpacity }
            deleteButton.layer.shadowOpacity = shadowOpacity
            enterButton.layer.shadowOpacity = shadowOpacity
            spaceButton.layer.shadowOpacity = shadowOpacity
            emptyButton.layer.shadowOpacity = shadowOpacity
        }
    }
}
