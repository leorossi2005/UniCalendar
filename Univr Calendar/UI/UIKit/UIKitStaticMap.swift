//
//  UIKitStaticMap.swift
//  Univr Calendar
//
//  Created by Leonardo Rossi on 15/12/25.
//

import SwiftUI
import MapKit

struct UIKitStaticMap: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    var padding: CGFloat = 0
    var altitude: CLLocationDistance = 1000
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.isUserInteractionEnabled = false
        mapView.insetsLayoutMarginsFromSafeArea = false
        mapView.preservesSuperviewLayoutMargins = false
        mapView.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        
        let zoomnRange = MKMapView.CameraZoomRange(minCenterCoordinateDistance: altitude, maxCenterCoordinateDistance: altitude)
        mapView.setCameraZoomRange(zoomnRange, animated: false)
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        let camera = MKMapCamera(
            lookingAtCenter: coordinate,
            fromDistance: altitude,
            pitch: 0,
            heading: 0
        )
        mapView.setCamera(camera, animated: false)
        
        mapView.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }
}
