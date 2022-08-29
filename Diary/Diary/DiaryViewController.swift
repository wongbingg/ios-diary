//
//  DiaryViewController.swift
//  Diary
//
//  Created by unchain, 웡빙 on 2022/08/17.
//

import UIKit
import CoreLocation

final class DiaryViewController: UIViewController {
    // MARK: - NameSpace
    
    private enum AlertMassage {
        static let shareActionTitle = "share..."
        static let deleteActionTitle = "Delete"
        static let cancel = "취소"
        static let deleteAlertTitle = "진짜요?"
        static let deleteAlertMessage = "정말로 삭제하시겠어요?"
        static let cancelActionTitle = "Cancel"
        static let newDiary = "새로운일기장"
    }
    
    // MARK: - Properties
    
    let diaryView = DiaryView(frame: .zero)
    var coreDataDiary: Diary?
    var mode: PageMode? = .create
    var locationManager: CLLocationManager!
    var lat: String?
    var lon: String?
    
    // MARK: - ViewLifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupInitialView()
        setupKeyboard()
        setupNotification()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showUpKeyboard()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        performAppropriateMode()
        NetworkManager.shared.requestWeatherData(latitude: lat, longitude: lon) { data in
            print(data.weather[0].main)
            print(data.weather[0].icon)
            print(data.name)
            print(data.sys.country)
            DispatchQueue.main.async {
                let action = UIAlertAction(title: "네", style: .default)
                self.generateAlertController(title: "알림", message: "위치업데이트완료", style: .alert, actions: [action])
            }
        }
    }
    
    // MARK: - UI Methods
    
    private func setupNavigationBar() {
        let now = Date()
        navigationItem.title = now.timeIntervalSince1970.translateToDate()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: SystemName.moreViewIcon),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(showActionSheet))
    }
    
    private func setupInitialView() {
        view.backgroundColor = .systemBackground
        view.addSubview(diaryView)
        setDiaryViewConstraint()
        diaryView.setupData(with: coreDataDiary)
    }
    
    private func setDiaryViewConstraint() {
        diaryView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            diaryView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            diaryView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            diaryView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            diaryView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func generateAlertController(title: String?, message: String?, style: UIAlertController.Style, actions: [UIAlertAction]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        actions.forEach { action in
            alert.addAction(action)
        }
        present(alert, animated: true)
    }
    
    private func generateShareAlertAction() -> UIAlertAction {
        let model = makeDiaryModel()
        let share = UIAlertAction(title: AlertMassage.shareActionTitle, style: .default) { [weak self] _ in
            let diaryToShare: [Any] = [MyActivityItemSource(title: model.title, text: model.body)]
            let activityViewController = UIActivityViewController(activityItems: diaryToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self?.diaryView
            
            self?.present(activityViewController, animated: true)
        }
        return share
    }
    
    private func generateDeleteAlertAction() -> UIAlertAction {
        let delete = UIAlertAction(title: AlertMassage.deleteActionTitle, style: .destructive) { [weak self] _ in
            guard let coreDataDiary = self?.coreDataDiary else { return }
            let cancel = UIAlertAction(title: AlertMassage.cancel, style: .cancel)
            let delete = UIAlertAction(title: NameSpace.delete, style: .destructive) { [weak self] _ in
                CoreDataManager.shared.delete(diary: coreDataDiary)
                self?.navigationController?.popViewController(animated: true)
            }
            self?.generateAlertController(title: AlertMassage.deleteAlertTitle, message: AlertMassage.deleteAlertMessage, style: .alert, actions: [cancel, delete])
        }
        return delete
    }
    
    private func generateCancelAlertAction() -> UIAlertAction {
        return UIAlertAction(title: AlertMassage.cancelActionTitle, style: .cancel)
    }
    
    @objc private func showActionSheet() {
        let share = generateShareAlertAction()
        let delete = generateDeleteAlertAction()
        let cancel = generateCancelAlertAction()
        generateAlertController(title: nil, message: nil, style: .actionSheet, actions: [share, cancel, delete])
    }
}

// MARK: - CoreDataManager Methods

extension DiaryViewController {
    private func setupNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateDiary), name: .update, object: nil)
    }
    
    private func performAppropriateMode() {
        switch mode {
        case .create:
            createDiary()
        case .modify:
            modifyDiary()
        default:
            return
        }
    }
    
    private func createDiary() {
        guard diaryView.diaryTextView.text.isEmpty == false else { return }
        let diaryModel = makeDiaryModel()
        CoreDataManager.shared.create(with: diaryModel)
    }
    
    private func modifyDiary() {
        guard let coreDataDiary = coreDataDiary else { return }
        if diaryView.diaryTextView.text.isEmpty || diaryView.diaryTextView.text == NameSpace.placeHolder {
            CoreDataManager.shared.delete(diary: coreDataDiary)
        } else {
            updateDiary()
        }
    }
    
    private func makeDiaryModel() -> DiaryModel {
        let distinguishedTitleAndBody = diaryView.diaryTextView.text.components(separatedBy: NameSpace.twiceLineChange)
        let createdAt = Date().timeIntervalSince1970
        let filteredList = distinguishedTitleAndBody.filter { return $0 != NameSpace.whiteSpace && $0 != NameSpace.lineChange }
        guard filteredList.isEmpty == false else {
            let title = AlertMassage.newDiary
            let body = NameSpace.whiteSpace
            return DiaryModel(title: String(title), body: String(body), createdAt: createdAt)
        }
        
        let title = distinguishedTitleAndBody[0]
        let body = distinguishedTitleAndBody.count == 1 ? NameSpace.whiteSpace : distinguishedTitleAndBody[1...distinguishedTitleAndBody.count-1].joined(separator: NameSpace.twiceLineChange)
        return DiaryModel(title: String(title), body: String(body), createdAt: createdAt)
    }
    
    @objc private func updateDiary() {
        guard let coreDataDiary = coreDataDiary else { return }
        let diaryModel = makeDiaryModel()
        CoreDataManager.shared.update(diary: coreDataDiary, with: diaryModel)
    }
}

// MARK: - Keyboard Methods

extension DiaryViewController {
    private func setupKeyboard() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillAppear),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillDisAppear),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
        diaryView.closeButton.addTarget(self,
                                        action: #selector(hideKeyboard),
                                        for: .touchUpInside)
    }
    
    private func showUpKeyboard() {
        if mode == .create {
            diaryView.diaryTextView.becomeFirstResponder()
        }
    }
    
    @objc private func keyboardWillAppear(_ sender: Notification) {
        guard let userInfo = sender.userInfo, let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let contentInset = UIEdgeInsets(top: .zero, left: .zero, bottom: keyboardFrame.size.height, right: .zero)
        diaryView.diaryTextView.contentInset = contentInset
        diaryView.diaryTextView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func keyboardWillDisAppear(_ sender: Notification) {
        let contentInset = UIEdgeInsets.zero
        diaryView.diaryTextView.contentInset = contentInset
        diaryView.diaryTextView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func hideKeyboard(_ sender: Any) {
        view.endEditing(true)
        updateDiary()
    }
}

// MARK: - CLLocationManagerDelegate

extension DiaryViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            print("")
            print("===============================")
            print("[ViewController > locationManager() : 위치 사용 권한 항상 허용]")
            print("===============================")
            print("")
        }
        if status == .authorizedWhenInUse {
            print("")
            print("===============================")
            print("[ViewController > locationManager() : 위치 사용 권한 앱 사용 시 허용]")
            print("===============================")
            print("")
        }
        if status == .denied {
            print("")
            print("===============================")
            print("[ViewController > locationManager() : 위치 사용 권한 거부]")
            print("===============================")
            print("")
        }
        if status == .restricted || status == .notDetermined {
            print("")
            print("===============================")
            print("[ViewController > locationManager() : 위치 사용 권한 대기 상태]")
            print("===============================")
            print("")
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
//        print("lat: \(locValue.latitude) , lon: \(locValue.longitude)")
        if let location = locations.last {
            lat = String(location.coordinate.latitude)
            lon = String(location.coordinate.longitude)
        }
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}
