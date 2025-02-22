//
//  HabitDetailViewController.swift
//  Zakkuri
//
//  Created by mironal on 2019/09/22.
//  Copyright © 2019 mironal. All rights reserved.
//

import RxCocoa
import RxSwift
import UIKit

public class HabitDetailViewController: UITableViewController {
    public var viewModel: HabitDetailViewModel!
    private let disposeBag = DisposeBag()

    @IBOutlet var closeButton: UIBarButtonItem!
    private let deleteItemRelay = PublishRelay<IndexPath>()

    public override func viewDidLoad() {
        super.viewDidLoad()

        let outputs = viewModel.bind(.init(
            tapClose: closeButton.rx.tap.asObservable(),
            deleteItem: deleteItemRelay.asObservable()
        ))

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.maximumUnitCount = 2
        formatter.unitsStyle = .abbreviated

        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateFormat = "YYYY/MM/dd"

        outputs.habitRecords.bind(to: tableView.rx.items(cellIdentifier: "cell")) { _, record, cell in
            cell.textLabel?.text = formatter.string(from: record.duration)
            cell.detailTextLabel?.text = dateFormatter.string(from: record.createdAt)
        }.disposed(by: disposeBag)

        outputs.dismiss.asSignal(onErrorJustReturn: ())
            .emit(onNext: {
                self.dismiss(animated: true)
            }).disposed(by: disposeBag)
    }

    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    public override func tableView(_: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, success in
            guard let self = self else { return }

            UIAlertController.confirmDelete()(self).subscribe(onNext: {
                switch $0 {
                case .cancel:
                    success(false)
                case .delete:
                    self.deleteItemRelay.accept(indexPath)
                    success(true)
                }
            }).disposed(by: self.disposeBag)
        }

        delete.backgroundColor = Theme.defailt.accentColor

        let config = UISwipeActionsConfiguration(actions: [delete])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
}
