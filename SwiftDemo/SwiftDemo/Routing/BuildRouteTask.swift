//
//  BuildRouteTask.swift
//  SwiftDemo
//
//  Created by Arkadiy Tolkun on 6/3/20.
//  Copyright © 2020 Evgen Bodunov. All rights reserved.
//

import Foundation
import GLRoute

class BuildRouteTask: Task {
    enum Result {
        case success(result: Route)
        case error(error: Error)
        case elevationUpdated
        case reset
    }

    private static let OfflineValhallaConfig: String = {
        guard let path = Bundle.main.path(forResource: "valhalla", ofType: "json"),
              let rv = try? String(contentsOfFile: path) else { fatalError("Error reading valhalla config") }
        return rv
    }()

    let params: RouteParams
    private var onFinish: (() -> Void)?
    private var taskID = Int64(0)
    private(set) var result: Result?

    init(params: RouteParams) {
        self.params = params
    }

    override func cancel() {
        super.cancel()
        GLRouteRequest.cancel(taskID)
    }

    override func isEqual(to: Task) -> Bool {
        return params == (to as? BuildRouteTask)?.params
    }

    override func start(_ onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        let request = GLRouteRequest()
        switch params.mode {
        case .pedestrian:
            request.setPedestrianWithOptions(CostingOptionsPedestrian())
        case .bicycle:
            request.setBicycleWithOptions(CostingOptionsBicycle())
        case .straight:
            request.setStraightWithOptions(CostingOptionsStraight())
        default:
            request.setAutoWithOptions(CostingOptionsAuto())
        }
        request.locale = "en-US"
        request.unitSystem = .international
        for pt in params.points {
            request.add(pt.pt)
        }
        taskID = request.start { route, error in
            if let error = error {
                let nsError = error as NSError
                if nsError.domain == "Valhalla" || nsError.code == ECANCELED {
                    self.result = .error(error: error)
                    self.onFinish?()
                } else { // Network error. Try to build offline
                    request.setOfflineWithConfig(BuildRouteTask.OfflineValhallaConfig)
                    self.taskID = request.start { route, error in
                        if let error = error {
                            self.result = .error(error: error)
                        } else if let route = route {
                            self.result = .success(result: Route(route: route, params: self.params))
                        } else {
                            let error = NSError(domain: GLMapViewErrorDomain, code: Int(POSIXErrorCode.EILSEQ.rawValue))
                            self.result = .error(error: error)
                        }
                        self.onFinish?()
                    }
                }
            } else if let route = route {
                self.result = .success(result: Route(route: route, params: self.params))
                self.onFinish?()
            } else {
                let error = NSError(domain: GLMapViewErrorDomain, code: Int(POSIXErrorCode.EILSEQ.rawValue))
                self.result = .error(error: error)
                self.onFinish?()
            }
        }
    }
}
