//
//  PlacesListViewController.swift
//  TravelBook
//
//  Created by Yea on 3.09.2022.
//

import UIKit
import CoreData

class PlacesListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!

    private let cellIdentifier = "PlaceCell"
    private var places = [PlaceListItem]()
    private var chosenPlaceID: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Travel Book"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonClicked))

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getData()
    }

    private var context: NSManagedObjectContext {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Unable to access AppDelegate")
        }
        return appDelegate.persistentContainer.viewContext
    }

    private func getData() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        ]

        do {
            let results = try context.fetch(fetchRequest)
            places = results.compactMap { object in
                guard
                    let place = object as? NSManagedObject,
                    let id = place.value(forKey: "id") as? UUID
                else {
                    return nil
                }

                let title = place.value(forKey: "title") as? String
                let subtitle = place.value(forKey: "subtitle") as? String
                return PlaceListItem(id: id, title: title?.nonEmptyValue ?? "Untitled place", subtitle: subtitle?.nonEmptyValue)
            }
            tableView.reloadData()
            updateEmptyState()
        } catch {
            showAlert(title: "Could not load places", message: error.localizedDescription)
        }
    }

    @objc func addButtonClicked() {
        chosenPlaceID = nil
        performSegue(withIdentifier: "interface", sender: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let place = places[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = place.title
        content.secondaryText = place.subtitle
        content.image = UIImage(systemName: "mappin.and.ellipse")
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        chosenPlaceID = places[indexPath.row].id
        performSegue(withIdentifier: "interface", sender: nil)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        deletePlace(at: indexPath)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "interface" {
            guard let destinationVC = segue.destination as? ViewController else { return }
            destinationVC.selectedTitleID = chosenPlaceID
        }
    }

    private func deletePlace(at indexPath: IndexPath) {
        let place = places[indexPath.row]
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
        fetchRequest.predicate = NSPredicate(format: "%K == %@", "id", place.id as NSUUID)
        fetchRequest.fetchLimit = 1

        do {
            if let object = try context.fetch(fetchRequest).first as? NSManagedObject {
                context.delete(object)
                try context.save()
            }
            places.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            updateEmptyState()
        } catch {
            context.rollback()
            showAlert(title: "Could not delete place", message: error.localizedDescription)
        }
    }

    private func updateEmptyState() {
        guard places.isEmpty else {
            tableView.backgroundView = nil
            return
        }

        let label = UILabel()
        label.text = "No saved places yet"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        tableView.backgroundView = label
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private struct PlaceListItem {
    let id: UUID
    let title: String
    let subtitle: String?
}

private extension String {
    var nonEmptyValue: String? {
        let trimmedValue = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
