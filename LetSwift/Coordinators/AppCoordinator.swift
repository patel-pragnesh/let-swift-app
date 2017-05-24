//
//  AppCoordinator.swift
//  LetSwift
//
//  Created by Marcin Chojnacki, Kinga Wilczek on 13.04.2017.
//  Copyright © 2017 Droids On Roids. All rights reserved.
//

import UIKit

protocol AppCoordinatorDelegate: class {
    func presentLoginViewController(asPopupWindow: Bool)
}

final class AppCoordinator: Coordinator, AppCoordinatorDelegate, Startable {
    
    fileprivate var initialEventsList: [Event]? = nil
    
    fileprivate var shouldShowLoginScreen: Bool {
        return !(FacebookManager.shared.isLoggedIn || DefaultsManager.shared.isLoginSkipped)
    }
    
    func start() {
        navigationViewController.setNavigationBarHidden(true, animated: false)
        
        presentSplashScreen()
    }
    
    private func present(viewController: UIViewController, animated: Bool = true) {
        navigationViewController.setViewControllers([viewController], animated: animated)
    }
    
    fileprivate func presentSplashScreen() {
        let viewModel = SplashViewControllerViewModel(delegate: self)
        let viewController = SplashViewController(viewModel: viewModel)
        
        present(viewController: viewController, animated: false)
    }
    
    fileprivate func presentFirstAppController() {
        if !DefaultsManager.shared.isOnboardingCompleted {
            presentOnboardingViewController()
        } else if shouldShowLoginScreen {
            presentLoginViewController()
        } else {
            presentMainController()
        }
    }
    
    fileprivate func presentOnboardingViewController() {
        let viewModel = OnboardingViewControllerViewModel(delegate: self)
        let viewController = OnboardingViewController(viewModel: viewModel)
        
        present(viewController: viewController)
    }
    
    func presentLoginViewController(asPopupWindow: Bool = false) {
        let viewModel = LoginViewControllerViewModel(delegate: self)
        let viewController = LoginViewController(viewModel: viewModel)
        
        if asPopupWindow {
            navigationViewController.pushViewController(viewController, animated: true)
        } else {
            present(viewController: viewController)
        }
    }
    
    fileprivate func presentMainController() {
        let coordinators = [
            EventsCoordinator(navigationController: UINavigationController(), initialEventsList: initialEventsList, delegate: self),
            SpeakersCoordinator(navigationController: UINavigationController()),
            ContactCoordinator(navigationController: UINavigationController())
        ]
        
        coordinators.forEach {
            ($0 as! Startable).start()
            self.childCoordinators.append($0)
        }

        let viewController = TabBarViewController(controllers: coordinators.map({ ($0).navigationViewController }))
        
        present(viewController: viewController)
    }
}

extension AppCoordinator: SplashViewControllerDelegate {
    func initialLoadingHasFinished(events: [Event]?) {
        self.initialEventsList = events
        presentFirstAppController()
    }
}

extension AppCoordinator: OnboardingViewControllerCoordinatorDelegate {
    func onboardingHasCompleted() {
        DefaultsManager.shared.isOnboardingCompleted = true

        shouldShowLoginScreen ? presentLoginViewController() : presentMainController()
    }
}

extension AppCoordinator: LoginViewControllerDelegate {
    func facebookLoginCompleted() {
        if navigationViewController.viewControllers.count > 1 {
            navigationViewController.popViewController(animated: true)
        } else {
            presentMainController()
        }
    }
    
    func loginHasSkipped() {
        DefaultsManager.shared.isLoginSkipped = true
        
        if navigationViewController.viewControllers.count > 1 {
            navigationViewController.popViewController(animated: true)
        } else {
            presentMainController()
        }
    }
}
