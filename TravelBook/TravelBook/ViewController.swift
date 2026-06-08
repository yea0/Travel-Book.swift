//
//  ViewController.swift
//  TravelBook
//
//  Created by Yea on 29.08.2022.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var noteText: UITextField!

    private let locationManager = CLLocationManager()
    private var selectedCoordinate: CLLocationCoordinate2D?
    private var selectedPlace: NSManagedObject?

    var selectedTitleID : UUID?


    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        configureMap()
        configureLocationManager()
        loadSelectedPlaceIfNeeded()
    }

    private var context: NSManagedObjectContext {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Unable to access AppDelegate")
        }
        return appDelegate.persistentContainer.viewContext
    }

    private var isEditingExistingPlace: Bool {
        selectedPlace != nil
    }

    private func configureView() {
        title = selectedTitleID == nil ? "New Place" : "Place Details"
        navigationItem.largeTitleDisplayMode = .never
        nameText.delegate = self
        noteText.delegate = self
        nameText.returnKeyType = .next
        noteText.returnKeyType = .done
    }

    private func configureMap() {
        mapView.delegate = self

        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 1
        mapView.addGestureRecognizer(gestureRecognizer)
    }

    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    private func loadSelectedPlaceIfNeeded() {
        guard let selectedTitleID else { return }

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
        fetchRequest.predicate = NSPredicate(format: "%K == %@", "id", selectedTitleID as NSUUID)
        fetchRequest.fetchLimit = 1
        fetchRequest.returnsObjectsAsFaults = false

        do {
            guard let place = try context.fetch(fetchRequest).first as? NSManagedObject else {
                showAlert(title: "Place not found", message: "This place may have been removed.")
                return
            }

            selectedPlace = place
            let title = place.value(forKey: "title") as? String ?? ""
            let subtitle = place.value(forKey: "subtitle") as? String ?? ""
            let latitude = place.value(forKey: "latitude") as? Double ?? 0
            let longitude = place.value(forKey: "longitude") as? Double ?? 0
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

            nameText.text = title
            noteText.text = subtitle
            selectedCoordinate = coordinate
            addAnnotation(title: title, subtitle: subtitle, coordinate: coordinate, shouldReplaceExisting: true)
            focusMap(on: coordinate, animated: false)
        } catch {
            showAlert(title: "Could not load place", message: error.localizedDescription)
        }
    }

    @objc private func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }

        view.endEditing(true)
        let touchedPoint = gestureRecognizer.location(in: mapView)
        let touchedCoordinate = mapView.convert(touchedPoint, toCoordinateFrom: mapView)
        selectedCoordinate = touchedCoordinate

        addAnnotation(title: nameText.text, subtitle: noteText.text, coordinate: touchedCoordinate, shouldReplaceExisting: true)
        focusMap(on: touchedCoordinate, animated: true)

    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard selectedCoordinate == nil, let location = locations.last else { return }
        focusMap(on: location.coordinate, animated: true)
        locationManager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            showAlert(title: "Location unavailable", message: "You can still save places by long-pressing the map.")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    @IBAction func saveButton(_ sender: Any) {
        view.endEditing(true)

        guard let title = nameText.text?.nonEmptyValue else {
            showAlert(title: "Name required", message: "Add a name before saving this place.")
            return
        }

        guard let coordinate = selectedCoordinate else {
            showAlert(title: "Location required", message: "Long-press the map to drop a pin before saving.")
            return
        }

        let place = selectedPlace ?? NSEntityDescription.insertNewObject(forEntityName: "Place", into: context)
        place.setValue(title, forKey: "title")
        place.setValue(noteText.text?.nonEmptyValue, forKey: "subtitle")
        place.setValue(coordinate.latitude, forKey: "latitude")
        place.setValue(coordinate.longitude, forKey: "longitude")

        if !isEditingExistingPlace {
            place.setValue(UUID(), forKey: "id")
        }

        do {
            try context.save()
            navigationController?.popViewController(animated: true)
        } catch {
            context.rollback()
            showAlert(title: "Could not save place", message: error.localizedDescription)
        }
    }

    private func addAnnotation(title: String?, subtitle: String?, coordinate: CLLocationCoordinate2D, shouldReplaceExisting: Bool) {
        if shouldReplaceExisting {
            mapView.removeAnnotations(mapView.annotations)
        }

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = title?.nonEmptyValue ?? "Selected place"
        annotation.subtitle = subtitle?.nonEmptyValue
        mapView.addAnnotation(annotation)
    }

    private func focusMap(on coordinate: CLLocationCoordinate2D, animated: Bool) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: animated)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nameText:
            noteText.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}

private extension String {
    var nonEmptyValue: String? {
        let trimmedValue = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}

