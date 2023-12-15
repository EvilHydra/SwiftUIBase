//
//  View.swift
//  SwiftUIDev
//
//  Created by Lothar on 2023/12/12.
//

import SwiftUI

public struct ViewPositionKey: PreferenceKey {
    public typealias Value = ViewCoordinate
    
    public static var defaultValue: ViewCoordinate = ViewCoordinate(id: "", name: "")
    
    public static func reduce(value: inout ViewCoordinate, nextValue: () -> ViewCoordinate) {
        value = nextValue()
    
    }
}


public struct VisibleModifier: ViewModifier {
    
    @Binding public private(set) var isVisible: Bool?
    
    public var coordinate: ViewCoordinate?
    
    public func body(content: Content) -> some View {

        content
            .background(GeometryReader(content: { geometry in
                let selfCoordinate = ViewCoordinate(id: UUID().uuidString, proxy: geometry, referCoordinate: coordinate)
                Color.clear.preference(key: ViewPositionKey.self, value: selfCoordinate)
            })
            .onPreferenceChange(ViewPositionKey.self) { position in
                DispatchQueue.main.async {
//                    print(position.proxy?.frame(in: .named("SwiftUIDev.FakeCollectionView<Swift.String>")))
                    if position.isVisibleOnSuperView() == true {
                        updateIsVisible(true)
                    } else {
                        updateIsVisible(false)
                    }
                }
            })
        
        
        
    }
    
    func updateIsVisible(_ isVisible: Bool) {
        guard self.isVisible != isVisible else { return }
        self.isVisible = isVisible
        
        print(isVisible ? "visible" : "invisible")
    }
}

public extension View {
    func isVisible(_ binding: Binding<Bool?> = .constant(nil), coordinate: ViewCoordinate?) -> some View {
        let view = modifier(VisibleModifier(isVisible: binding, coordinate: coordinate))
        return view
    }
}


public struct ViewCoordinate: Equatable {
    public static func == (lhs: ViewCoordinate, rhs: ViewCoordinate) -> Bool {
        lhs.id == rhs.id
    }
    
    public let id: String
    public private(set) var proxy: GeometryProxy?
    public private(set) var name: AnyHashable?
    
    // because of recursive, so use array to break it.
    private let referCoordinates: [ViewCoordinate]?
    
    // MARK: - Getter
    public var referCoordinate: ViewCoordinate? { referCoordinates?.first }
    
    public var space: CoordinateSpace {
        guard let name = name else {
            return .global
        }
        return .named(name)
    }
    
    public init(id: String, proxy: GeometryProxy? = nil, name: AnyHashable? = nil, referCoordinate: ViewCoordinate? = nil) {
        self.id = id
        self.name = name
        self.proxy = proxy
        
        if let referCoordinate = referCoordinate {
            self.referCoordinates = [referCoordinate]
        } else {
            self.referCoordinates = nil
        }
    }
    
    
    public func isVisibleOnSuperView() -> Bool {
        guard let name = referCoordinate?.name else { return false }
        let space = CoordinateSpace.named(name)
        print("space: \(space)")
        guard let frame = referCoordinate?.proxy?.frame(in: space) else { return false }
        return proxy?.isVisible(on: space, frame: frame) == true
    }
    
}

public extension GeometryProxy {

    func isVisible(on space: CoordinateSpace? = nil, frame: CGRect? = nil) -> Bool {
        
        let coordinate: CoordinateSpace
        let referFrame: CGRect
        if let space = space, let frame = frame {
            coordinate = space
            referFrame = frame
        } else {
            coordinate = .global
            referFrame = UIScreen.main.bounds
        }

        let rect = self.frame(in: coordinate)
    
        let intersection = rect.intersection(referFrame)
        let intersectionArea = intersection.width * intersection.height
        
        let viewArea = rect.width * rect.height
        let intersectionPercentage = intersectionArea / viewArea
        
        print("cor:\(coordinate) rect: \(rect) -- referFrame: \(referFrame) -- intersection: \(intersection)")
        
        if intersectionPercentage > 0.3 {
            return true
        } else {
            return false
        }
    }
}
