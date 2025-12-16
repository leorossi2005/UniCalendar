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
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.isUserInteractionEnabled = false
        mapView.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        let region = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
        mapView.setRegion(region, animated: false)
        
        mapView.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }
}



#Preview {
    //SimpleStaticMap()
}
