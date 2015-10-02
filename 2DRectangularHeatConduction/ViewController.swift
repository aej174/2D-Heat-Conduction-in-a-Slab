//
//  ViewController.swift
//  2DRectangularHeatConduction
//
//  Created by Allan Jones on 9/25/15.
//  Copyright © 2015 Allan Jones. All rights reserved.
/*
    The slab may be viewed as a rectangle and is divided into rectangular elements, where numberOfColumns is the number of divisions in the horizontal (East - West) direction and numberOfRows is the number of divisions in the vertical (North-South) direction. The origin of the coordinate system is the southwest corner of the rectangle.  The variable j counts the number of divisions in the easterly direction from 0 to numberOfColumns - 1, while i counts the number of divisions in the northerly direction from 0 to numberOf Rows - 1.  The (numberOfColumns) X (numberOfRows) heat balance equations for each element are solved by a relaxation method.
*/

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var slabWidthTextField: UITextField!
    @IBOutlet weak var slabHeightTextField: UITextField!
    @IBOutlet weak var thermalConductivityTextField: UITextField!
    
    @IBOutlet weak var northBoundaryTempTextField: UITextField!
    @IBOutlet weak var northHTCoefficientTextField: UITextField!
    @IBOutlet weak var eastBoundaryTempTextField: UITextField!
    @IBOutlet weak var eastHTCoefficientTextField: UITextField!
    @IBOutlet weak var southBoundaryTempTextField: UITextField!
    @IBOutlet weak var southHTCoefficientTextField: UITextField!
    @IBOutlet weak var westBoundaryTempTextField: UITextField!
    @IBOutlet weak var westHTCoefficientTextField: UITextField!
    
    @IBOutlet weak var heatTransferRateTextField: UITextField!
    
    @IBOutlet weak var tableView: UITableView!
    
    
    let numberOfRows = 12
    let numberOfColumns = 12
    
    var areas = [[Area]]()
    var eachArea = Area()
    
    var rows:[Area] = []
    
    var profileArray:[Dictionary<String,String>] = []
    
    var dx = 0.0
    var dy = 0.0
    var heatTransferRate = 0.0
    var thisTemperature = 0.0
    
    var temperatures = Array(count: 12, repeatedValue: Array(count: 12, repeatedValue: 0.0))
    var pastTemperatures = Array(count: 12, repeatedValue: Array(count: 12, repeatedValue: 0.0))

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        for _ in 0..<numberOfRows {
            rows.append(eachArea)
            for _ in 0..<numberOfColumns {
                areas.append(rows)
            }
        }
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        for var i = 0; i < numberOfRows; i++ {
            
            for  j in 0..<numberOfColumns {
                let yy = Double(round(100 * temperatures[i][j]) / 100)
                //print("At i = \(i), j = \(j), temperature = \(yy)")
                profileArray.append(["Column" : "\(j)", "Temperature" : "\(yy)"])
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Mark: UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return numberOfRows
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (numberOfColumns)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let profileDict:Dictionary = profileArray[indexPath.row]
        let cell: ProfileCell = tableView.dequeueReusableCellWithIdentifier("myCell") as! ProfileCell
        cell.columnLabel.text = profileDict["Column"]
        cell.temperatureLabel.text = profileDict["Temperature"]
        return cell
    }
    
    //Mark: UITableViewDelegate
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Row \(section)      Column                Temperature"
    }
    

    //Mark: Enter data values and calculate results
    
    @IBAction func calculateButtonPressed(sender: UIButton) {
        
        let slabWidth = Double((slabWidthTextField.text as String?)!)!
        let slabHeight = Double((slabHeightTextField.text as String?)!)!
        let thermalConductivity = Double((thermalConductivityTextField.text as String?)!)!
        let northBoundaryTemp = Double((northBoundaryTempTextField.text as String?)!)!
        let northHTCoefficient = Double((northHTCoefficientTextField.text as String?)!)!
        let eastBoundaryTemp = Double((eastBoundaryTempTextField.text as String?)!)!
        let eastHTCoefficient = Double((eastHTCoefficientTextField.text as String?)!)!
        let southBoundaryTemp = Double((southBoundaryTempTextField.text as String?)!)!
        let southHTCoefficient = Double((southHTCoefficientTextField.text as String?)!)!
        let westBoundaryTemp = Double((westBoundaryTempTextField.text as String?)!)!
        let westHTCoefficient = Double((westHTCoefficientTextField.text as String?)!)!
        
        let avgBoundaryTemp = (northBoundaryTemp + eastBoundaryTemp + southBoundaryTemp + westBoundaryTemp) / 4.0
        
        var northCoeff = 0.0
        var eastCoeff = 0.0
        var southCoeff = 0.0
        var westCoeff = 0.0
        
        if northHTCoefficient < 0.0001 {
            northCoeff = 0.0001             //this avoids "divide by zero" for insulated surfaces
        }
        else {
            northCoeff = northHTCoefficient
        }
        if eastHTCoefficient < 0.0001 {
            eastCoeff = 0.0001
        }
        else {
            eastCoeff = eastHTCoefficient
        }
        if southHTCoefficient < 0.0001 {
            southCoeff = 0.0001
        }
        else {
            southCoeff = southHTCoefficient
        }
        if westHTCoefficient < 0.0001 {
            westCoeff = 0.0001
        }
        else {
            westCoeff = westHTCoefficient
        }
        print("northCoeff = \(northCoeff), eastCoeff = \(eastCoeff), southCoeff = \(southCoeff), west coeff = \(westCoeff)")
        
        var UN = 0.0
        var UE = 0.0
        var US = 0.0
        var UW = 0.0
        var TN = 0.0
        var TE = 0.0
        var TS = 0.0
        var TW = 0.0
        
        let maxi = numberOfRows - 1
        let maxj = numberOfColumns - 1
                
        dx = slabWidth / Double(numberOfRows)
        dy = slabHeight / Double(numberOfColumns)
        print("dx = \(dx), dy = \(dy)")
        
        for var i = 0; i < numberOfRows; i++ {
            for var j = 0; j < numberOfColumns; j++ {
                temperatures[i][j] = avgBoundaryTemp        //initial values to begin iterations
            }
        }
        
        var notDone:Bool = true
        var iterations = 0
        
        while notDone {
            
            iterations = iterations + 1
            
            var maxDeviation = 0.0
            
            for var i = 0; i < numberOfRows; i++ {
                for var j = 0; j < numberOfColumns; j++ {
                    pastTemperatures[i][j] = temperatures[i][j]
                }
            }
            
            for var i = 0; i < numberOfRows; i++ {
                for var j = 0; j < numberOfColumns; j++ {
                    
                    if i == 0 {
                        US = 1.0 / (dx / (2.0 * thermalConductivity) + 1.0 / southCoeff)
                        TS = southBoundaryTemp
                        UN = thermalConductivity / dx
                        TN = pastTemperatures[i+1][j]
                        
                        if j == 0 {
                            UW = 1.0 / (dy / (2.0 * thermalConductivity) + 1.0 / westCoeff)
                            TW = westBoundaryTemp
                            UE = thermalConductivity / dy
                            TE = pastTemperatures[i][j+1]
                        
                            temperatures[i][j] = (dy * (US * TS + UN * TN) + dx * (UE * TE + UW * TW)) / (dy * (US + UN) + dx  * (UW + UE))
                        }
                        else if j == maxj {
                            UE = 1.0 / (dy / (2.0 * thermalConductivity) + 1.0 / eastCoeff)
                            TE = eastBoundaryTemp
                            UW = thermalConductivity / dy
                            TW = pastTemperatures[i][j-1]
                        
                            temperatures[i][j] = (dy * (US * TS + UN * TN) + dx * (UE * TE + UW * TW)) / (dy * (US + UN) + dx  * (UW + UE))
                        }
                        else {
                            UW = thermalConductivity / dy
                            TW = pastTemperatures[i][j-1]
                            UE = thermalConductivity / dy
                            TE = pastTemperatures[i][j+1]
                        
                            temperatures[i][j] = (dy * (US * TS + UN * TN) + dx * (UE * TE + UW * TW)) / (dy * (US + UN) + dx  * (UW + UE))
                        }
                    }
                
                    if i == maxi {
                        US = thermalConductivity / dx
                        TS = pastTemperatures[i-1][j]
                        UN = 1.0 / (dx / (2.0 * thermalConductivity) + 1.0 / northCoeff)
                        TN = northBoundaryTemp
                    
                        if j == 0 {
                            UW = 1.0 / (dy / (2.0 * thermalConductivity) + 1.0 / westCoeff)
                            TW = westBoundaryTemp
                            UE = thermalConductivity / dy
                            TE = pastTemperatures[i][j+1]
                        
                            temperatures[i][j] = (dy * (US * TS + UN * TN) + dx * (UE * TE + UW * TW)) / (dy * (US + UN) + dx  * (UW + UE))
                        }
                        else if j == maxj {
                            UE = 1.0 / (dy / (2.0 * thermalConductivity) + 1.0 / eastHTCoefficient)
                            TE = eastBoundaryTemp
                            UW = thermalConductivity / dy
                            TW = temperatures[i][j-1]
                        
                            temperatures[i][j] = (dy * (US * TS + UN * TN) + dx * (UE * TE + UW * TW)) / (dy * (US + UN) + dx  * (UW + UE))
                        }
                        else {
                            UW = thermalConductivity / dy
                            TW = temperatures[i][j-1]
                            UE = thermalConductivity / dy
                            TE = temperatures[i][j+1]
                        
                            temperatures[i][j] = (dy * (US * TS + UN * TN) + dx * (UE * TE + UW * TW)) / (dy * (US + UN) + dx  * (UW + UE))
                        }
                    }
                
                    if (i != 0) && (i != maxi) {
                        US = thermalConductivity / dx
                        TS = pastTemperatures[i-1][j]
                        UN = thermalConductivity / dx
                        TN = pastTemperatures[i+1][j]
                    
                        if j == 0 {
                            UW = 1.0 / (dy / (2.0 * thermalConductivity) + 1.0 / westCoeff)
                            TW = westBoundaryTemp
                            UE = thermalConductivity / dy
                            TE = pastTemperatures[i][j+1]
                        
                            temperatures[i][j] = (dy * (US * TS + UN * TN) + dx * (UE * TE + UW * TW)) / (dy * (US + UN) + dx  * (UW + UE))
                        }
                        else if j == maxj {
                            UE = 1.0 / (dy / (2.0 * thermalConductivity) + 1.0 / eastCoeff)
                            TE = eastBoundaryTemp
                            UW = thermalConductivity / dy
                            TW = pastTemperatures[i][j-1]
                        
                            temperatures[i][j] = (dy * (US * TS + UN * TN) + dx * (UE * TE + UW * TW)) / (dy * (US + UN) + dx  * (UW + UE))
                        }
                        else {
                            UW = thermalConductivity / dy
                            TW = temperatures[i][j-1]
                            UE = thermalConductivity / dy
                            TE = temperatures[i][j+1]
                        
                            temperatures[i][j] = (dy * (US * TS + UN * TN) + dx * (UE * TE + UW * TW)) / (dy * (US + UN) + dx  * (UW + UE))
                        }
                        if abs(temperatures[i][j] - pastTemperatures[i][j]) > maxDeviation {
                            maxDeviation = abs(temperatures[i][j] - pastTemperatures[i][j])
                        }
                    }
                }  //end i
            }  //end j
            
            if maxDeviation < 0.001 || iterations > 500 {
                notDone = false
                print("max deviation = \(maxDeviation)")
            }
            
        }  //end while
        
        var qSouth = 0.0
        US = 1.0 / (dx / (2.0 * thermalConductivity) + 1.0 / southCoeff)
        TS = southBoundaryTemp
        print("US = \(US), TS = \(TS)")
        for var j = 0; j < numberOfColumns; j++ {
            qSouth = qSouth + US * dy * (TS - temperatures[0][j])
        }
        var qNorth = 0.0
        UN = 1.0 / (dx / (2.0 * thermalConductivity) + 1.0 / northCoeff)
        TN = northBoundaryTemp
        print("UN = \(UN), TN = \(TN)")
        for var j = 0; j < numberOfColumns; j++ {
            qNorth = qNorth + UN * dy * (TN - temperatures[maxi][j])
        }
        var qEast = 0.0
        UE = 1.0 / (dy / (2.0 * thermalConductivity) + 1.0 / eastCoeff)
        TE = eastBoundaryTemp
        print("UE = \(UE), TE = \(TE)")
        for var i = 0; i < numberOfRows; i++ {
            qEast = qEast + UE * dx * (TE - temperatures[i][maxj])
        }
        var qWest = 0.0
        UW = 1.0 / (dy / (2.0 * thermalConductivity) + 1.0 / westCoeff)
        TW = westBoundaryTemp
        print("UW = \(UW), TW = \(TW)")
        for var i = 0; i < numberOfRows; i++ {
            qWest = qWest + UW * dx * (TW - temperatures[i][0])
        }
        print("qNorth = \(qNorth), qEast = \(qEast), qSouth = \(qSouth), qWest = \(qWest)")
        if qNorth > 0.0 {
            heatTransferRate = heatTransferRate + qNorth
        }
        if qEast > 0.0 {
            heatTransferRate = heatTransferRate + qEast
        }
        if qSouth > 0.0 {
            heatTransferRate = heatTransferRate + qSouth
        }
        if qWest > 0.0 {
            heatTransferRate = heatTransferRate + qWest
        }
        
        let zz = Double(round(100 * heatTransferRate) / 100)
        print("HeatTransferRate = \(zz)")
        
        self.heatTransferRateTextField.text = "\(zz)"
        
        profileArray = []
        
        print("after \(iterations) iterations:")
        print("")
        for var i = 0; i < numberOfRows; i++ {
            for var j = 0; j < numberOfColumns; j++ {
                //let xx = Double(round(100 * pastTemperatures[i][j]) / 100)
                let yy = Double(round(100 * temperatures[i][j]) / 100)
                print("At i = \(i), j = \(j), temperature = \(yy)")
                profileArray.append(["Column" : "\(j)", "Temperature" : "\(yy)"])
            }
        }
        self.tableView.reloadData()


    } //end func calculate


} // end program

