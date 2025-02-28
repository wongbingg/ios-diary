//
//  CoreDataManager.swift
//  Diary
//
//  Created by unchain, 웡빙 on 2022/08/22.
//
import UIKit
import CoreData

protocol CoreDataManagerDelegate: AnyObject {
    func didCreateCoreData()
    func didUpdateCoreData()
}

final class CoreDataManager {
    weak var delegate: CoreDataManagerDelegate?
    private(set) var fetchedDiaries: [Diary] = []
    static let shared = CoreDataManager()
    private lazy var context = persistentContainer.viewContext

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Diary")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    private init() {
        fetch()
    }
    
    func create(with model: DiaryModel) {
        let newItem = Diary(context: context)
        newItem.setValue(model.title, forKey: CoreDataKeys.title)
        newItem.setValue(model.body, forKey: CoreDataKeys.body)
        newItem.setValue(model.createdAt, forKey: CoreDataKeys.createdAt)
        newItem.setValue(model.weatherIcon, forKey: "weatherIcon")
        do {
            try context.save()
            fetch()
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didCreateCoreData()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func delete(diary: Diary) {
        context.delete(diary)
        do {
            try context.save()
            fetch()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func update(diary: Diary, with diaryModel: DiaryModel) {
        guard diary.title != diaryModel.title || diary.body != diaryModel.body else { return }
        diary.title = diaryModel.title
        diary.body = diaryModel.body
        diary.createdAt = diaryModel.createdAt
        
        do {
            try context.save()
            fetch()
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didUpdateCoreData()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func fetch() {
        do {
            let reversed = try context.fetch(Diary.fetchRequest()).reversed()
            fetchedDiaries = reversed.map { $0 }
        } catch {
            print(error.localizedDescription)
        }
    }
}
