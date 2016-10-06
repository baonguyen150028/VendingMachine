//
//  ViewController.swift
//  VendingMachine
//
//  Created by TheBao on 10/06/16.
//  Copyright © 2016 TheBao. All rights reserved.
//

import UIKit

private let reuseIdentifier = "vendingItem"
private let screenWidth = UIScreen.main.bounds.width

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!

    let vendingMachine: VendingMachineType
    var currentSelection: VendingSelection?
    var quantity: Double = 1.0
    required init?(coder aDecoder: NSCoder) {

        do{
            let dictionary = try plistConveter.dictionaryFromFile(resource: "VendingInventory", ofType: "plist")
            let inventory = try InventoryUnarchiver.vendingInventoryFromDictionary(dictionary: dictionary)
            self.vendingMachine = VendingMachine(inventory: inventory)
        } catch let error {
            fatalError("\(error)")
        }
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setupCollectionViewCells()
        print(vendingMachine.inventory)

       setupViews()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func setupViews(){
        updateQuantityLabel()
        updateBalanceLabel()
    }
    // MARK: - UICollectionView 

    func setupCollectionViewCells() {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 20, left: 0, bottom: 10, right: 0)
        let padding: CGFloat = 10
        layout.itemSize = CGSize(width: (screenWidth / 3) - padding, height: (screenWidth / 3) - padding)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        
        collectionView.collectionViewLayout = layout
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vendingMachine.selection.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! VendingItemCell

        let item = vendingMachine.selection[indexPath.row]

        cell.iconView.image = item.icon()

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateCellBackgroundColor(indexPath, selected: true)
        reset()

        currentSelection = vendingMachine.selection[indexPath.row]
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateCellBackgroundColor(indexPath, selected: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        updateCellBackgroundColor(indexPath, selected: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        updateCellBackgroundColor(indexPath, selected: false)
    }
    
    func updateCellBackgroundColor(_ indexPath: IndexPath, selected: Bool) {
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.backgroundColor = selected ? UIColor(red: 41/255.0, green: 211/255.0, blue: 241/255.0, alpha: 1.0) : UIColor.clear
        }
    }
    
    // MARK: - Helper Methods

    @IBAction func purchase() {

        if let currentSelection = currentSelection {
            do {
                try vendingMachine.vend(selection: currentSelection, quantity: quantity)
                balanceLabel.text = "$\(vendingMachine.amountDeposited)"

            } catch VendingMachineError.OutOfStock {
                showAlert(title: "Out Of Stock")
            } catch VendingMachineError.InvalidSelection {
                showAlert(title: "Invalid Selection!")
            } catch VendingMachineError.InsufficientFunds(required: let amount){
                showAlert(title: "Insufficient Funds", message: "Additional $\(amount) need to complete the transaction.")
            } catch let error {
                fatalError("\(error)")
            }
        } else {

            // FIXME: Alert user to no selection
        }
        
    }

    @IBAction func updateQuantity(_ sender: UIStepper) {

        quantity = sender.value
        updateTotalPriceLabel()
        updateQuantityLabel()
    }

    func updateTotalPriceLabel(){

        if let currentSelection = currentSelection, let item = vendingMachine.itemForCurrent(selection: currentSelection){

            totalLabel.text = "$\(item.price * quantity)"
        }
    }
    func updateQuantityLabel(){
        quantityLabel.text = "\(quantity)"
    }
    func updateBalanceLabel(){
        balanceLabel.text = "$\(vendingMachine.amountDeposited)"
    }
    func reset(){
        quantity = 1
        updateTotalPriceLabel()
        updateQuantityLabel()
    }

    func showAlert(title: String, message: String? = nil, style: UIAlertControllerStyle = .alert){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default) { (action) in
            self.dismiss(animated: true, completion: nil)
            self.reset()
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)

    }

    @IBAction func depositFunds() {

        vendingMachine.deposit(amount: 5.0)
        updateBalanceLabel()
    }
}

