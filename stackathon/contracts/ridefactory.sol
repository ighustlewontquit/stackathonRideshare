pragma solidity ^0.4.19;

import "./ownable.sol";

contract RideFactory is Ownable{
    
    event NewRide(uint _rideId, bytes32 _start, bytes32 _end, uint _cost);
    event NewWant(uint _rideId, bytes32 _start, bytes32 _end, uint _cost);

    struct RideOffer{
        bytes32 start;
        bytes32 end;
        uint cost; 
        //should add an offer expiry
    }
    
    struct RideWanted{
        bytes32 start;
        bytes32 end;
        uint cost;
    }
    
    struct RidesInProgress{
        address driver;
        address passenger;
        bytes32 start;
        bytes32 end;
        uint cost;
        bool complete;
    }
    
    bytes32 finalstart;
    bytes32 finalend;
    address finaldriver;
    address finalpassenger;
    uint256 finalcost;
    string finaldepartAt;
    string finalarriveAt;
    string usertype;
    bool matched;
    
    
    RideOffer[] public availRideOffers;
    RideWanted[] public availRideWants;
    RidesInProgress[] public matchedRides;
    
    mapping (uint => address) public ownerOfRide; 
    mapping (uint => address) public ownerOfWant;
    mapping (address => uint) rideIdOfDriver; 
    mapping (address => uint) rideIdOfPassenger;
    mapping (address => string) UserTypeOfAddress;
    
    
    function setUserType(string _usertype) public { //write variable
        while ((keccak256("driver") != keccak256(_usertype)) || (keccak256("rider") != keccak256(_usertype))){
        usertype = _usertype;
        UserTypeOfAddress[msg.sender] = _usertype;
        }
    }
    
    function createRide(bytes32 _start, bytes32 _end, uint _cost) public  {
        uint id = availRideOffers.push(RideOffer(_start, _end, _cost)) - 1;
        ownerOfRide[id] = msg.sender;
        emit NewRide(id, _start, _end, _cost);
    }
    
    function createWant(bytes32 _start, bytes32 _end, uint _cost) public  {
        uint id = availRideWants.push(RideWanted(_start, _end, _cost)) - 1;
        ownerOfWant[id] = msg.sender;
        emit NewWant(id, _start, _end, _cost);
    }
    
     function _createMatch (address _driver, address _passenger, bytes32 _start, bytes32 _end, uint _cost) internal { //need to set a modifer that only allows either the passenger or driver to do it
            matchedRides.push(RidesInProgress(_driver, _passenger, _start, _end, _cost, false)) - 1;
    }        
    
}  
 