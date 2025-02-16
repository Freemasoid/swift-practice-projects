//
//  CalculatorMain.swift
//  BMI Calculator
//
//  Created by Roman on 15.01.2025.
//  Copyright © 2025 Angela Yu. All rights reserved.
//

import Foundation
import UIKit

struct CalculatorMain {
    
    var bmi: BMI?
    
    func getBMIValue() -> String {
        let bmiValue = String(format: "%.1f", bmi?.value ?? 0.0)
        return bmiValue
    }
    
    func getAdvice() -> String {
        return bmi?.advice ?? "No advice"
    }
    
    func getColor() -> UIColor {
        return bmi?.color ?? UIColor.white
    }
    
    mutating func calculateBMI(height: Float, weight: Float) {
        let bmiValue = weight / (height * height)
        
        if bmiValue < 18.5 {
            bmi = BMI(value: bmiValue, advice: "Eat more pies!", color: UIColor.blue)
        } else if bmiValue < 25 {
            bmi = BMI(value: bmiValue, advice: "You're doing great!", color: UIColor.green)
        } else {
            bmi = BMI(value: bmiValue, advice: "You need to eat less pies!", color: UIColor.red)
        }
    }
}
