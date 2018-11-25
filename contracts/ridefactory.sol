pragma solidity ^0.4.19;

import "./ownable.sol";

contract RideFactory is Ownable{
    
    event NewRide(uint _rideId, string _start, string _end, uint _cost);
    event NewWant(uint _rideId, string _start, string _end, uint _cost);

    struct RideOffer{
        string start;
        string end;
        uint cost; 
        //should add an offer expiry
    }
    
    struct RideWanted{
        string start;
        string end;
        uint cost;
    }
    
    struct RidesInProgress{
        address driver;
        address passenger;
        string start;
        string end;
        uint cost;
        bool complete;
    }
    
    bool matched;
    
    RideOffer[] public availRideOffers;
    RideWanted[] public availRideWants;
    RidesInProgress[] public matchedRides;
    
    mapping (uint => address) public ownerOfRide; 
    mapping (uint => address) public ownerOfWant;
    mapping (address => uint) rideIdOfDriver; 
    mapping (address => uint) rideIdOfPassenger;
    
    
    function createRide(string _start, string _end, uint _cost) public  {
        uint id = availRideOffers.push(RideOffer(_start, _end, _cost)) - 1;
        ownerOfRide[id] = msg.sender;
        emit NewRide(id, _start, _end, _cost);
    }
    
    function createWant(string _start, string _end, uint _cost) public  {
        uint id = availRideWants.push(RideWanted(_start, _end, _cost)) - 1;
        ownerOfWant[id] = msg.sender;
        emit NewWant(id, _start, _end, _cost);
    }
    
}  
 