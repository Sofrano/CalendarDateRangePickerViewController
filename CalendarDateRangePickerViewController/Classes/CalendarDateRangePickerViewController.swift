//
//  CalendarDateRangePickerViewController.swift
//  CalendarDateRangePickerViewController
//
//  Created by Miraan on 15/10/2017.
//  Copyright © 2017 Miraan. All rights reserved.
//

import UIKit

public protocol CalendarDateRangePickerViewControllerDelegate {
    func didCancelPickingDateRange(_ viewController: CalendarDateRangePickerViewController)
    func didPickDateRange(_ viewController: CalendarDateRangePickerViewController,
                          startDate: Date!,
                          endDate: Date!)
}

public class CalendarDateRangePickerViewController: UICollectionViewController {
    
    let cellReuseIdentifier = "CalendarDateRangePickerCell"
    let headerReuseIdentifier = "CalendarDateRangePickerHeaderView"
    
    public var calendar = Calendar(identifier: .gregorian)
    public var delegate: CalendarDateRangePickerViewControllerDelegate!
    public var scrollToEnd: Bool = false
    public var scrollToDate: Date?
    public var titleCancel: String = "Cancel"
    public var titleDone: String = "Done"
    
    let itemsPerRow = 7
    let itemHeight: CGFloat = 40
    let collectionViewInsets = UIEdgeInsets(top: 0,
                                            left: 25,
                                            bottom: 0,
                                            right: 25)
    
    public var minimumDate: Date!
    public var maximumDate: Date!
    
    public var selectedStartDate: Date?
    public var selectedEndDate: Date?
    
    public var selectedColor = UIColor(red: 66/235.0,
                                       green: 150/255.0,
                                       blue: 240/255.0,
                                       alpha: 1.0)
    public var titleText = "Select Dates"

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = self.titleText
        
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.backgroundColor = UIColor.white

        collectionView?.register(CalendarDateRangePickerCell.self, forCellWithReuseIdentifier: cellReuseIdentifier)
        collectionView?.register(CalendarDateRangePickerHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier)
        collectionView?.contentInset = collectionViewInsets
        
        if minimumDate == nil {
            minimumDate = Date()
        }
        if maximumDate == nil {
            maximumDate = calendar.date(byAdding: .year, value: 3, to: minimumDate)
        }
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: titleCancel,
                                                                style: .plain,
                                                                target: self,
                                                                action: #selector(CalendarDateRangePickerViewController.didTapCancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: titleDone,
                                                                 style: .done,
                                                                 target: self,
                                                                 action: #selector(CalendarDateRangePickerViewController.didTapDone))
        //self.navigationItem.rightBarButtonItem?.isEnabled = selectedStartDate != nil
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if scrollToEnd {
            let difference = calendar.dateComponents([.month], from: minimumDate, to: maximumDate)
            collectionView?.scrollToItem(at: IndexPath(row: 0, section: difference.month! - 1),
                                         at: .top,
                                         animated: true)
        } else
            if let date = scrollToDate {
                let difference = calendar.dateComponents([.month], from: minimumDate, to: date)
                collectionView?.scrollToItem(at: IndexPath(row: 0, section: difference.month!),
                                             at: .top,
                                             animated: true)
        }
    }
    
    @objc func didTapCancel() {
        delegate.didCancelPickingDateRange(self)
    }
    
    @objc func didTapDone() {
        if selectedStartDate == nil {
            return
        }
        delegate.didPickDateRange(self, startDate: selectedStartDate!, endDate: selectedEndDate ?? selectedStartDate!)
    }
    
}

extension CalendarDateRangePickerViewController {
    
    // UICollectionViewDataSource
    
    override public func numberOfSections(in collectionView: UICollectionView) -> Int {
        let difference = calendar.dateComponents([.month], from: minimumDate, to: maximumDate)
        return difference.month! + 1
    }
    
    override public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let firstDateForSection = getFirstDateForSection(section: section)
        let weekdayRowItems = 7
        let blankItems = getWeekday(date: firstDateForSection) - 2
        let daysInMonth = getNumberOfDaysInMonth(date: firstDateForSection)
        return weekdayRowItems + blankItems + daysInMonth
    }
    
    override public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! CalendarDateRangePickerCell
        cell.selectedColor = self.selectedColor
        cell.reset()
        let blankItems = getWeekday(date: getFirstDateForSection(section: indexPath.section)) - 2
        var weekDay = indexPath.item + calendar.firstWeekday
        if weekDay == 8 {
            weekDay = 1
        }
        
        if (weekDay - 1) < 7 {
            cell.label.text = getWeekdayLabel(weekday: weekDay)
        } else if (weekDay - 2) < 7 + blankItems {
            cell.label.text = ""
        } else {
            let dayOfMonth = (weekDay - 1) - (7 + blankItems)
            let date = getDate(dayOfMonth: dayOfMonth, section: indexPath.section)
            cell.date = date
            cell.label.text = "\(dayOfMonth)"
            
            if isBefore(dateA: date, dateB: minimumDate) {
                cell.disable()
            }
            
            if selectedStartDate != nil && selectedEndDate != nil && isBefore(dateA: selectedStartDate!, dateB: date) && isBefore(dateA: date, dateB: selectedEndDate!) {
                // Cell falls within selected range
                if dayOfMonth == 1 {
                    cell.highlightRight()
                } else if dayOfMonth == getNumberOfDaysInMonth(date: date) {
                    cell.highlightLeft()
                } else {
                    cell.highlight()
                }
            } else if selectedStartDate != nil && areSameDay(dateA: date, dateB: selectedStartDate!) {
                // Cell is selected start date
                cell.select()
                if selectedEndDate != nil {
                    cell.highlightRight()
                }
            } else if selectedEndDate != nil && areSameDay(dateA: date, dateB: selectedEndDate!) {
                cell.select()
                cell.highlightLeft()
            }
        }
        return cell
    }
    
    override public func collectionView(_ collectionView: UICollectionView,
                                        viewForSupplementaryElementOfKind kind: String,
                                        at indexPath: IndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerReuseIdentifier, for: indexPath) as! CalendarDateRangePickerHeaderView
            headerView.label.text = getMonthLabel(date: getFirstDateForSection(section: indexPath.section))
            return headerView
        default:
            fatalError("Unexpected element kind")
        }
    }
    
}

extension CalendarDateRangePickerViewController : UICollectionViewDelegateFlowLayout {
    
    override public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! CalendarDateRangePickerCell
        if cell.date == nil {
            return
        }
        if isBefore(dateA: cell.date!, dateB: minimumDate) {
            return
        }
        if selectedStartDate == nil {
            selectedStartDate = cell.date
        } else if selectedEndDate == nil {
            if isBefore(dateA: selectedStartDate!, dateB: cell.date!) {
                selectedEndDate = cell.date
                self.navigationItem.rightBarButtonItem?.isEnabled = true
            } else {
                // If a cell before the currently selected start date is selected then just set it as the new start date
                selectedStartDate = cell.date
            }
        } else {
            selectedStartDate = cell.date
            selectedEndDate = nil
        }
        collectionView.reloadData()
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding = collectionViewInsets.left + collectionViewInsets.right
        let availableWidth = view.frame.width - padding
        let itemWidth = availableWidth / CGFloat(itemsPerRow)
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.size.width, height: 50)
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

extension CalendarDateRangePickerViewController {
    
    // Helper functions
    
    func getFirstDate() -> Date {
        var components = calendar.dateComponents([.month, .year], from: minimumDate)
        components.day = 1
        return calendar.date(from: components)!
    }
    
    
    func getFirstDateForSection(section: Int) -> Date {
        return calendar.date(byAdding: .month, value: section, to: getFirstDate())!
    }
    
    func getMonthLabel(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: date)
    }
    
    func getWeekdayLabel(weekday: Int) -> String {
        var components = DateComponents()
        components.calendar = calendar
        components.weekday = weekday
        let date = calendar.nextDate(after: Date(),
                                     matching: components,
                                     matchingPolicy: Calendar.MatchingPolicy.strict)
        if date == nil {
            return "E"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEEE"
        var result = dateFormatter.string(from: date!)
        return result
    }
    
    func getWeekday(date: Date) -> Int {
        return calendar.dateComponents([.weekday], from: date).weekday!
    }
    
    func getNumberOfDaysInMonth(date: Date) -> Int {
        return calendar.range(of: .day, in: .month, for: date)!.count
    }
    
    func getDate(dayOfMonth: Int, section: Int) -> Date {
        var components = calendar.dateComponents([.month, .year], from: getFirstDateForSection(section: section))
        components.day = dayOfMonth
        return calendar.date(from: components)!
    }
    
    func areSameDay(dateA: Date, dateB: Date) -> Bool {
        return calendar.compare(dateA, to: dateB, toGranularity: .day) == ComparisonResult.orderedSame
    }
    
    func isBefore(dateA: Date, dateB: Date) -> Bool {
        return calendar.compare(dateA, to: dateB, toGranularity: .day) == ComparisonResult.orderedAscending
    }
    
}
