pragma solidity ^0.4.19;

import "./ridefactory.sol";


    contract DriverInterface {
        function getPassenger(uint256 _rideId) external view returns (
        string _start,
        string _end,
        uint256 _cost,
        string _departAt,
        string _arriveAt
  );
}
 
    contract PassengerInterface {
        function getDriver(uint256 _rideId) external view returns (
        string _start,
        string _end,
        uint256 _cost,
        string _departAt,
        string _arriveAt
  );
}    //I need output from the outside
    
    contract RideMatcher is RideFactory {
        
        DriverInterface driverContract; //i need to output the ridedetails as a function of rideID which loops over in the front end. the user will then select the rideId which he wants 
        PassengerInterface passengerContract;
        
        function createMatch (address _driver, address _passenger, string _start, string _end, uint _cost) internal { //need to set a modifer that only allows either the passenger or driver to do it
        
            matchedRides.push(RidesInProgress(_driver, _passenger, _start, _end, _cost, false)) - 1;
            matched = true;
        
            uint rideIdDriver = rideIdOfDriver[_driver];
            uint rideIdPassenger = rideIdOfPassenger[_passenger];
        
            availRideOffers[rideIdDriver] = RideOffer("no", "no", 0);
            availRideWants[rideIdPassenger] = RideWanted("no", "no", 0);
            
            //need to execute payment from both parties but for now skip to the part, where the driver and passenger meet up and complete there ride.

    }         //set that the driver is ready
}

/**
 * 
 * 
 * 
 * 
     // if (zombieToOwner[i] == _owner) {
       // result[counter] = i;
        //counter++;
    
    
        for (uint i = 0; i < availRideOffers.length; i++){
            for (uint j = 0; j < availRideWants.length; j++){
                if (RideOffer[i] == RideWanted[j]){
                    matched = true;
contract CreatePassenger {
  function getRide(string _start, string _end, uint256 _id) external view returns (
    bool driverIsReady,
    bool passengerIsReady,
    uint256 departAt,
    uint256 arriveAt
  );

contract RideMatcher is RideFactory{
    
  RideInterface RideContract;

  modifier onlyOwnerOf(uint _rideId) {
    require(msg.sender == ownerOfRide[_rideId]);
    _;
  }
  //need to make it so that a current ride is not in progress
  
  function driverAcceptPassenger(uint _rideId) public view onlyOwnerOf(_rideId) {
    RideOffer memory myRide = availRideOffer[_rideId];
    //need to send reputation to the escrow
    
  }
    
}
}**/