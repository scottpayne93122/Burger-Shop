
// SPDX-License-Identifier: MIT

// This is a practice tutorial. Not production ready. 


pragma solidity >= 0.8.0 <0.9.0;

contract BurgerShop {
    address public owner;
    uint256 public cost = 0.2 ether;
    uint256 public deluxCost = 0.4 ether;
    mapping(address => uint256) public refundEligible;
    bool public paused = false;
    

    event BoughtBurger(address indexed _from, uint256 cost);

    // Remember stages are represented by integers - - see comments below
    enum Stages {
        readyToOrder, // 0
        makeBurger, // 1
        deliverBurger // 2
    }
    Stages public burgerShopStage = Stages.readyToOrder;

    constructor() {
        owner = msg.sender;
    }

    modifier shouldPay(uint256 _cost) {
        require(msg.value >= _cost, "Insufficient funds.");
        _;
    }

    modifier isAtStage(Stages _stage){
        require(burgerShopStage == _stage, "Not at correct Stage.");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    modifier notPaused() {
        require(paused == false, "Contract is paused.");
        _;
    }
    
    function buyBurger() payable public shouldPay(cost) isAtStage(Stages.readyToOrder) {
        updateStage(Stages.makeBurger);
        emit BoughtBurger(msg.sender, cost);   
    }

    function buyDeluxBurger() payable public shouldPay(deluxCost) isAtStage(Stages.readyToOrder) {
        updateStage(Stages.makeBurger);
        emit BoughtBurger(msg.sender, deluxCost);
    }

    function refund(address _to, uint256 _cost) payable public onlyOwner() {
        require(_cost == cost || _cost == deluxCost, "You can only refund cost of regular or cost of delux.");
        require(address(this).balance >= _cost, "Not enough funds!");

        refundEligible[_to] += _cost;
    }

    function claimRefund() payable public {
        uint256 value = refundEligible[msg.sender]; // assign variable to represent amount available for refund
        require(value != 0, "Not approved for refund."); // check: that value is present
        refundEligible[msg.sender] = 0; // effect: reset mapping value
        (bool success, ) = payable(msg.sender).call{value: value}(""); // interact: allow user to claim refund 
        require(success);
    }

    function contractFunds() public view returns(uint256) {
        return address(this).balance;
    }

    function madeBurger() public isAtStage(Stages.makeBurger) {
        updateStage(Stages.deliverBurger);
    }

    function pickupBurger() public isAtStage(Stages.deliverBurger) {
        updateStage(Stages.readyToOrder);
    }

    function updateStage(Stages _stage) public {
        burgerShopStage = _stage;
    }

    function withdraw() payable public {
        require(msg.sender == owner, "You are not the owner.");
        (bool success, ) = payable(owner).call{value: address(this).balance}("");
        require(success);
        
    }

    // This is not a reliable random number pattern because it's succeptable to miner manipulation, for theory practice only.
    function getRandomNum(uint256 _seed) public view returns(uint256) {
        uint256 randNum = uint256(keccak256(abi.encodePacked(block.timestamp, _seed))) % 10 + 1;
        return randNum;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
}
