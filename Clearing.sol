// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Updated_Peer-to-peerEnergy.sol";

contract ExchangeContract {
    address public ExchOwner;
    uint public tKStartTime = block.timestamp; // Replaced 'now' with 'block.timestamp'
    uint public tokenMarktTime = 240 minutes; // Time to clear Token Market (e.g., 4 hours)
    PeerEnergy interfcontract;

    // Modifier to check if the sender is an authorized smart meter
    modifier onlySmartMeter(address SMaddr) {
        require(
            interfcontract.checkSMNode(SMaddr) == true,
            "Sender not authorized."
        );
        _;
    }

    // Modifier to restrict access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == ExchOwner, "Sender not authorized.");
        _;
    }

    // Constructor to initialize the contract
    constructor(address _peerEnergyAddress) {
        ExchOwner = msg.sender;
        interfcontract = PeerEnergy(_peerEnergyAddress); // Dynamically set PeerEnergy contract address
    }

    // Function to clear energy orders
    function clearEnergy() public onlySmartMeter(msg.sender) {
        interfcontract.clearEnergyOrder(msg.sender);
    }

    // Function to clear token offers if the time has elapsed
    function clearToken() public onlySmartMeter(msg.sender) {
        if (block.timestamp >= tKStartTime + tokenMarktTime) {
            interfcontract.clearTokenOffers();
            tKStartTime += tokenMarktTime;
        }
    }

    // Function to restart trading, resetting the start time
    function restartTrade() public onlyOwner {
        interfcontract.restartTrade();
        tKStartTime = block.timestamp;
    }

    // Function to change token market time in minutes
    function changeTokenMarketTime(uint TimeInMins) public onlyOwner {
        tokenMarktTime = TimeInMins * 1 minutes;
    }
}































// pragma solidity ^0.4.25;

// import "./PeerEnergy.sol";

// contract ExchangeContract{
//     address ExchOwner;
//     uint public tKStartTime = now;//should be negative 3 hours
//     uint tokenMarktTime = 240 minutes;//Time to ckear Token Market (e.g is 4 hours)
//     PeerEnergy interfcontract = PeerEnergy(0xf005a6696522f21698558917c1a15222eeeab315);
    
//     modifier onlySmartMeter(address SMaddr) {
//          require(interfcontract.checkSMNode(SMaddr) == true,
// 		 "Sender not authorised.");
//          _;
//      }
    
//     constructor() public {
//     	ExchOwner = msg.sender;
//         }  
    
//     modifier onlyOwner() {
//     	require(msg.sender == ExchOwner, "Sender not authorised.");
//         _;
//     }
    
//     /*  */
//     function clearEnergy() public onlySmartMeter(msg.sender) {
//         //should be 29 minutes 
//         interfcontract.clearEnergyOrder(msg.sender);
//     }
    
    
//     /*  */
//     function clearToken() public onlySmartMeter(msg.sender){
//         if (now>=tKStartTime + tokenMarktTime){
//         	interfcontract.clearTokenOffers();
//         	tKStartTime += tokenMarktTime;
//         }
        
//     }
    
    
//     /*  */
//     function restartTrade() public onlyOwner() {
//         interfcontract.restartTrade();
//         tKStartTime = now;
//     }
    
    
//     //This function is use to change token market time in hours
//     function changeTokenMarketTime(uint TimeInMins) public onlyOwner() {
//         uint MarktTime = 60*TimeInMins;
//         tokenMarktTime = MarktTime;
//     }
// }




