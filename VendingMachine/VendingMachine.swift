//
//  VendingMachine.swift
//  VendingMachine
//
//  Created by The Bao on 10/06/16.
//  Copyright © 2016 TheBao. All rights reserved.
//

import Foundation
import UIKit

// Protocols

protocol VendingMachineType {

    var selection: [VendingSelection] { get }
    var inventory: [VendingSelection : ItemType] { get set }
    var amountDeposited: Double { get set }

    init (inventory: [VendingSelection: ItemType])
    func vend(selection: VendingSelection, quantity: Double) throws
    func itemForCurrent(selection: VendingSelection) -> ItemType?
    func deposit (amount: Double)
}

protocol ItemType {
    var price : Double { get }
    var quantity : Double { get set }
}
//Error Type

enum InventoryError:Error {
    case InvalidResource
    case ConversionError
    case InvalidKey
}
enum VendingMachineError:Error {
    case InvalidSelection
    case OutOfStock
    case InsufficientFunds(required: Double)
}
// Helper Classes

class plistConveter {

    class func dictionaryFromFile(resource: String, ofType type: String ) throws -> [String : AnyObject]{
        guard let path = Bundle.main.path(forResource: resource, ofType: type) else {
                throw InventoryError.InvalidResource
        }
        guard let dictionary = NSDictionary.init(contentsOfFile: path), let castDictionary = dictionary as? [String:AnyObject] else {
            throw InventoryError.ConversionError
        }
        return castDictionary
    }
}
    
class InventoryUnarchiver {

    class func vendingInventoryFromDictionary(dictionary: [String:AnyObject] ) throws -> [VendingSelection : ItemType] {

        var inventory: [VendingSelection : ItemType ] = [:]

        for (key,value) in dictionary {

            if let itemDict = value as? [String : Double],
                let price = itemDict["price"], let quantity = itemDict["quantity"]
                {
                    let item = VendingItem(price: price, quantity: quantity)

                    guard let key = VendingSelection(rawValue: key) else {
                        throw InventoryError.InvalidKey
                    }
                    inventory.updateValue(item, forKey: key)
            }

        }
        print(inventory)
        return inventory
    }

}


// Concrete Types
enum VendingSelection: String {
    case Soda
    case DietSoda
    case Chips
    case Cookie
    case Sandwich
    case Wrap
    case CandyBar
    case PopTart
    case Water
    case FruitJuice
    case SportsDrink
    case Gum

    func icon() -> UIImage {
        
        if let image =  UIImage(named: self.rawValue) {

            return image
        } else {
            return UIImage(named: "Default")!
        }
    }
}

struct VendingItem: ItemType {
    let price: Double
    var quantity: Double

}

class VendingMachine: VendingMachineType {

    var selection: [VendingSelection] = [.Soda, .DietSoda, .Chips, .Cookie, .Sandwich, .Wrap, .CandyBar, .PopTart, .Water, .FruitJuice, .SportsDrink, .Gum]
    var inventory: [VendingSelection : ItemType]
    var amountDeposited: Double = 10
    required init(inventory: [VendingSelection : ItemType]) {
        self.inventory = inventory
    }
    func vend(selection: VendingSelection, quantity: Double) throws {
        guard var item = inventory[selection] else {
            throw VendingMachineError.InvalidSelection
        }
        guard item.quantity > 0 else {
            throw VendingMachineError.OutOfStock
        }
        item.quantity -= quantity
        inventory.updateValue(item, forKey: selection)
        let totalPrice = item.price * quantity
        if amountDeposited >= totalPrice {
            amountDeposited -= totalPrice
        } else {
            let amountRequired = totalPrice - amountDeposited
            throw VendingMachineError.InsufficientFunds(required: amountRequired)
        }

    }
    func itemForCurrent (selection: VendingSelection) -> ItemType? {
    
        return inventory[selection]
    }


    func deposit(amount: Double) {
        amountDeposited += amount 
    }


}
