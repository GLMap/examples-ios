//
//  RouteHelper.swift
//  SwiftDemo
//
//  Created by Arkadiy Tolkun on 6/3/20.
//  Copyright © 2020 Evgen Bodunov. All rights reserved.
//

import Foundation
import GLRoute

protocol RouteHelperDelegate: AnyObject {
    func routeParamsChanged()
    func routeChanged(_ result: BuildRouteTask.Result?)
    func routeIsUpdatingChanged()
}

class RouteHelper {
    private lazy var oneTaskGuard = OneTaskGuard<BuildRouteTask> { [weak self] _ in self?.taskFinished() }
    lazy var delayedUpdate = DelayedBlock(delay: 5) { [weak self] in self?.update() }
    var params: RouteParams {
        didSet { delegate?.routeParamsChanged() }
    }

    private(set) var isUpdatingRoute = false {
        didSet { delegate?.routeIsUpdatingChanged() }
    }

    private var elevationUpdateTaskID: Int64? {
        didSet { delegate?.routeIsUpdatingChanged() }
    }

    var isUpdating: Bool { isUpdatingRoute || elevationUpdateTaskID != nil }
    weak var delegate: RouteHelperDelegate?

    init(params: RouteParams) {
        self.params = params
    }

    private func taskFinished() {
        isUpdatingRoute = false
        delayedUpdate.cancel()
        delegate?.routeChanged(oneTaskGuard.lastQuery?.result)

        switch oneTaskGuard.lastQuery?.result {
        case let .success(result):
            if result.params.mode == .walk || result.params.mode == .cycle {
                elevationUpdateTaskID = GLRouteElevation.requestHeight(for: result.route) { [weak self] _, _ in
                    guard let self = self else { return }
                    self.elevationUpdateTaskID = nil
                    self.delegate?.routeChanged(.elevationUpdated)
                }
            }
        default:
            break
        }
    }

    func cancel() {
        oneTaskGuard.push(nil)
        if let taskID = elevationUpdateTaskID {
            elevationUpdateTaskID = nil
            GLRouteElevation.cancel(taskID)
        }
    }

    func update(_ params: RouteParams) {
        self.params = params
        update()
    }

    func update() {
        if let taskID = elevationUpdateTaskID {
            elevationUpdateTaskID = nil
            GLRouteElevation.cancel(taskID)
        }
        if params.points.count >= 2 {
            isUpdatingRoute = true
            oneTaskGuard.push(BuildRouteTask(params: params))
        } else {
            delegate?.routeChanged(.reset)
        }
    }
}
