pragma solidity ^0.4.18;
import "./ERC20.sol";
//import "./ownable.sol";

/// @title modified from StandardBounties by Mark Beylin <mark.beylin@consensys.net>
/// @dev Used to pay out individuals or groups for task fulfillment through
/// stepwise work submission, acceptance, and payment
contract CarpoolBounties {

  event BountyIssued(uint bountyId);
  event BountyActivated(uint bountyId, address issuer);
  event BountyFulfilled(uint bountyId, address indexed fulfiller, uint256 indexed _fulfillmentId);
  event FulfillmentUpdated(uint _bountyId, uint _fulfillmentId);
  event FulfillmentAccepted(uint bountyId, address indexed fulfiller, uint256 indexed _fulfillmentId);
  event BountyKilled(uint bountyId, address indexed issuer);
  event ContributionAdded(uint bountyId, address indexed contributor, uint256 value);
  event DeadlineExtended(uint bountyId, uint newDeadline);
  event BountyChanged(uint bountyId);
  event IssuerTransferred(uint _bountyId, address indexed _newIssuer);
  event PayoutIncreased(uint _bountyId, uint _newFulfillmentAmount);
  
  address public owner;

  Bounty[] public bounties;

  mapping(uint=>Fulfillment[]) fulfillments;
  mapping(uint=>uint) numAccepted;
  mapping(uint=>ERC20) tokenContracts;

  enum BountyStages {
      Draft,
      Active,
      Dead
  }

  struct Bounty {
      address issuer;
      uint deadline;
      uint long;
      uint lat;
      uint fulfillmentAmount;
      address arbiter;
      bool paysTokens;
      BountyStages bountyStage;
      uint balance;
  }

  struct Fulfillment {
      bool accepted;
      address fulfiller;
      uint long;
      uint lat;
  }

  modifier validateNotTooManyBounties(){
    require((bounties.length + 1) > bounties.length);
    _;
  }

  modifier validateNotTooManyFulfillments(uint _bountyId){
    require((fulfillments[_bountyId].length + 1) > fulfillments[_bountyId].length);
    _;
  }

  modifier validateBountyArrayIndex(uint _bountyId){
    require(_bountyId < bounties.length);
    _;
  }

  modifier onlyIssuer(uint _bountyId) {
      require(msg.sender == bounties[_bountyId].issuer);
      _;
  }

  modifier onlyFulfiller(uint _bountyId, uint _fulfillmentId) {
      require(msg.sender == fulfillments[_bountyId][_fulfillmentId].fulfiller);
      _;
  }

  modifier amountIsNotZero(uint _amount) {
      require(_amount != 0);
      _;
  }

  modifier transferredAmountEqualsValue(uint _bountyId, uint _amount) {
      if (bounties[_bountyId].paysTokens){
        require(msg.value == 0);
        uint oldBalance = tokenContracts[_bountyId].balanceOf(this);
        if (_amount != 0){
          require(tokenContracts[_bountyId].transferFrom(msg.sender, this, _amount));
        }
        require((tokenContracts[_bountyId].balanceOf(this) - oldBalance) == _amount);

      } else {
        require((_amount * 1 wei) == msg.value);
      }
      _;
  }

  modifier isBeforeDeadline(uint _bountyId) {
      require(now < bounties[_bountyId].deadline);
      _;
  }

  modifier validateDeadline(uint _newDeadline) {
      require(_newDeadline > now);
      _;
  }

  modifier isAtStage(uint _bountyId, BountyStages _desiredStage) {
      require(bounties[_bountyId].bountyStage == _desiredStage);
      _;
  }

  modifier validateFulfillmentArrayIndex(uint _bountyId, uint _index) {
      require(_index < fulfillments[_bountyId].length);
      _;
  }

  modifier notYetAccepted(uint _bountyId, uint _fulfillmentId){
      require(fulfillments[_bountyId][_fulfillmentId].accepted == false);
      _;
  }

  function StandardBounties(address _owner)
      public
  {
      owner = _owner;
  }

  function issueBounty( //the driver should be using this function 
      address _issuer,
      uint _deadline,
      uint _long,
      uint _lat,
      uint256 _fulfillmentAmount,
      address _arbiter,
      bool _paysTokens,
      address _tokenContract
  )
      public
      validateDeadline(_deadline)
      //amountIsNotZero(_fulfillmentAmount)
      validateNotTooManyBounties
      returns (uint)
  {
      bounties.push(Bounty(_issuer, _deadline, _long, _lat, _fulfillmentAmount, _arbiter, _paysTokens, BountyStages.Draft, 0));
      if (_paysTokens){
        tokenContracts[bounties.length - 1] = ERC20(_tokenContract);
      }
      emit BountyIssued(bounties.length - 1);
      return (bounties.length - 1);
  }
  
  function issueAndActivateBounty( //the rider should be using this function
      address _issuer,
      uint _deadline,
      uint _long,
      uint _lat,
      uint256 _fulfillmentAmount,
      address _arbiter,
      bool _paysTokens,
      address _tokenContract,
      uint256 _value
  )
      public
      payable
      validateDeadline(_deadline)
      //amountIsNotZero(_fulfillmentAmount)
      validateNotTooManyBounties
      returns (uint)
  {
      require (_value >= _fulfillmentAmount); //driverssettheprice
      uint beforebalance = msg.value;
      uint afterbalance = beforebalance - _value;
      if (_paysTokens){
        require(msg.value == afterbalance);
        tokenContracts[bounties.length] = ERC20(_tokenContract);
        require(tokenContracts[bounties.length].transferFrom(msg.sender, this, _value));
      } else {
        require((_value * 1 wei) == msg.value);
      }
      bounties.push(Bounty(_issuer,
                            _deadline,
                            _long,
                            _lat,
                            _fulfillmentAmount,
                            _arbiter,
                            _paysTokens,
                            BountyStages.Active,
                            _value));
      emit BountyIssued(bounties.length - 1);
      emit ContributionAdded(bounties.length - 1, msg.sender, _value);
      emit BountyActivated(bounties.length - 1, msg.sender);
      return (bounties.length - 1);
  }

  modifier isNotDead(uint _bountyId) {
      require(bounties[_bountyId].bountyStage != BountyStages.Dead);
      _;
  }
  
  function activateBounty(uint _bountyId, uint _value) //driver uses this function to pay himself - should be at the start of the ride
      payable
      public
      validateBountyArrayIndex(_bountyId)
      isBeforeDeadline(_bountyId)
      onlyIssuer(_bountyId)
      transferredAmountEqualsValue(_bountyId, _value)
  {
      bounties[_bountyId].balance += _value; //need to pay escrow instead some reputation tokens
      require (bounties[_bountyId].balance >= bounties[_bountyId].fulfillmentAmount);
      transitionToState(_bountyId, BountyStages.Active);

      //emit ContributionAdded(_bountyId, msg.sender, _value);
      emit BountyActivated(_bountyId, msg.sender);
  }

  modifier notIssuerOrArbiter(uint _bountyId) {
      require(msg.sender != bounties[_bountyId].issuer && msg.sender != bounties[_bountyId].arbiter);
      _;
  }

  function fulfillBounty(uint _bountyId, uint _long, uint _lat) //driver confirms ride has ended
      public
      validateBountyArrayIndex(_bountyId)
      validateNotTooManyFulfillments(_bountyId)
      isAtStage(_bountyId, BountyStages.Active)
      isBeforeDeadline(_bountyId)
      notIssuerOrArbiter(_bountyId)
  {
      fulfillments[_bountyId].push(Fulfillment(false, msg.sender, _long, _lat));

      emit BountyFulfilled(_bountyId, msg.sender, (fulfillments[_bountyId].length - 1));
  }

  function updateFulfillment(uint _bountyId, uint _fulfillmentId, uint _long, uint _lat) //rider should confirm the has started
      public
      validateBountyArrayIndex(_bountyId)
      validateFulfillmentArrayIndex(_bountyId, _fulfillmentId)
      onlyFulfiller(_bountyId, _fulfillmentId)
      notYetAccepted(_bountyId, _fulfillmentId)
  {
      fulfillments[_bountyId][_fulfillmentId].long = _long;
      fulfillments[_bountyId][_fulfillmentId].lat = _lat;
      emit FulfillmentUpdated(_bountyId, _fulfillmentId);
  }

  modifier onlyIssuerOrArbiter(uint _bountyId) {
      require(msg.sender == bounties[_bountyId].issuer ||
         (msg.sender == bounties[_bountyId].arbiter && bounties[_bountyId].arbiter != address(0)));
      _;
  }

  modifier fulfillmentNotYetAccepted(uint _bountyId, uint _fulfillmentId) {
      require(fulfillments[_bountyId][_fulfillmentId].accepted == false);
      _;
  }

  modifier enoughFundsToPay(uint _bountyId) {
      require(bounties[_bountyId].balance >= bounties[_bountyId].fulfillmentAmount);
      _;
  }
  
  function acceptFulfillment(uint _bountyId, uint _fulfillmentId) //rider should confirm that ride has ended
      public
      validateBountyArrayIndex(_bountyId)
      validateFulfillmentArrayIndex(_bountyId, _fulfillmentId)
      onlyIssuerOrArbiter(_bountyId)
      isAtStage(_bountyId, BountyStages.Active)
      fulfillmentNotYetAccepted(_bountyId, _fulfillmentId)
      enoughFundsToPay(_bountyId)
  {
      fulfillments[_bountyId][_fulfillmentId].accepted = true;
      numAccepted[_bountyId]++;
      bounties[_bountyId].balance -= bounties[_bountyId].fulfillmentAmount;
      if (bounties[_bountyId].paysTokens){
        require(tokenContracts[_bountyId].transfer(fulfillments[_bountyId][_fulfillmentId].fulfiller, bounties[_bountyId].fulfillmentAmount));
      } else {
        fulfillments[_bountyId][_fulfillmentId].fulfiller.transfer(bounties[_bountyId].fulfillmentAmount);
      }
      emit FulfillmentAccepted(_bountyId, msg.sender, _fulfillmentId);
  }

  function killBounty(uint _bountyId) //if driver wants to cancel the ride 
      public
      validateBountyArrayIndex(_bountyId)
      onlyIssuer(_bountyId)
  {
      transitionToState(_bountyId, BountyStages.Dead);
      uint oldBalance = bounties[_bountyId].balance;
      bounties[_bountyId].balance = 0;
      if (oldBalance > 0){
        if (bounties[_bountyId].paysTokens){
          require(tokenContracts[_bountyId].transfer(bounties[_bountyId].issuer, oldBalance));
        } else {
          bounties[_bountyId].issuer.transfer(oldBalance);
        }
      }
      emit BountyKilled(_bountyId, msg.sender);
  }

  modifier newDeadlineIsValid(uint _bountyId, uint _newDeadline) {
      require(_newDeadline > bounties[_bountyId].deadline);
      _;
  }

  function extendDeadline(uint _bountyId, uint _newDeadline) //if
      public
      validateBountyArrayIndex(_bountyId)
      onlyIssuer(_bountyId)
      newDeadlineIsValid(_bountyId, _newDeadline)
  {
      bounties[_bountyId].deadline = _newDeadline;

      emit DeadlineExtended(_bountyId, _newDeadline);
  }

  function transitionToState(uint _bountyId, BountyStages _newStage)
      internal
  {
      bounties[_bountyId].bountyStage = _newStage;
  }
}