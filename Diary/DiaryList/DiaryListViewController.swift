//
//  Diary - DiaryListViewController.swift
//  Created by yagom. 
//  Copyright © yagom. All rights reserved.
// 

import UIKit

final class DiaryListViewController: UIViewController {
    // MARK: - NameSpace

    private enum DiaryListNameSpace {
        static let diary = "일기장"
        static let share = "공유"
        static let noneTitle = "제목없음"
    }

    // MARK: - Properties
    
    private let diaryListView = DiaryListView(frame: .zero)
    
    // MARK: - ViewLifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupDiaryListView()
        adaptDelegate()
        CoreDataManager.shared.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        diaryListView.tableView.reloadData()
    }
    
    // MARK: - Methods
    
    private func setupNavigationBar() {
        navigationItem.title = DiaryListNameSpace.diary
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addButtonDidTapped))
    }
    
    private func setupDiaryListView() {
        view.addSubview(diaryListView)
        diaryListView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            diaryListView.topAnchor.constraint(equalTo: view.topAnchor),
            diaryListView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            diaryListView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            diaryListView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func adaptDelegate() {
        diaryListView.tableView.delegate = self
    }
    
    @objc func addButtonDidTapped() {
        let diaryViewController = DiaryViewController()
        navigationController?.pushViewController(diaryViewController, animated: true)
    }
}

// MARK: - UITableViewDelegate

extension DiaryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let diaryViewController = generateViewController(with: indexPath.row)
        navigationController?.pushViewController(diaryViewController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let shareAction = generateShareAction(with: indexPath.row)
        let deleteAction = generateDeleteAction(with: indexPath, in: tableView)
        return UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
    }
}

// MARK: - UITableViewDelegate Support Methods

private extension DiaryListViewController {
    
    func generateShareAction(with indexPath: Int) -> UIContextualAction {
        let shareAction = UIContextualAction(style: .normal, title: DiaryListNameSpace.share) { [weak self] _, _, _ in
            guard let self = self else { return }
            let model = CoreDataManager.shared.fetchedDiaries
            let title = model[indexPath].title ?? DiaryListNameSpace.noneTitle
            let body = model[indexPath].body ?? DiaryListNameSpace.noneTitle
            let diaryToShare: [MyActivityItemSource] = [MyActivityItemSource(title: title, text: body)]
            let activityViewController = UIActivityViewController(activityItems: diaryToShare, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.diaryListView
            
            self.present(activityViewController, animated: true)
        }
        shareAction.image = UIImage(systemName: SystemName.shareIcon)
        shareAction.backgroundColor = .init(red: 80/255, green: 188/225, blue: 223/225, alpha: 1)
        return shareAction
    }
    
    func generateDeleteAction(with indexPath: IndexPath, in tableView: UITableView) -> UIContextualAction {
        let deleteAction = UIContextualAction(style: .destructive, title: NameSpace.delete) { _, _, _ in
            let diary = CoreDataManager.shared.fetchedDiaries[indexPath.row]
            CoreDataManager.shared.delete(diary: diary)
            tableView.performBatchUpdates {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }

        }
        deleteAction.image = UIImage(systemName: SystemName.deleteIcon)
        return deleteAction
    }
    
    func generateViewController(with indexPath: Int) -> UIViewController {
        let diaryViewController = DiaryViewController()
        diaryViewController.diary = CoreDataManager.shared.fetchedDiaries[indexPath]
        return diaryViewController
    }
}

// MARK: - CoreDataManagerDelegate

extension DiaryListViewController: CoreDataManagerDelegate {
    func didUpdateCoreData() {
        self.diaryListView.tableView.reloadData()
    }
    
    func didCreateCoreData() {
        self.diaryListView.tableView.performBatchUpdates {
            self.diaryListView.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        }
    }
}
