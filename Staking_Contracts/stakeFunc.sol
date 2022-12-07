// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

contract stacks{

    uint times;
    modifier updateTime(uint t){
        t = times;
            _;
    } 
    struct User{
        uint amount;
        uint time;
        uint withdrown;
        // address addr;
    }

    mapping (address => User ) public users;
    function userStake(uint amt) public returns(uint){
        users[msg.sender].amount = amt;
        users[msg.sender].time = block.timestamp;
        // users.time = block.timestamp;
    }

    function updateValue() public  returns(uint) {
       require (block.timestamp >= users[msg.sender].time+ 60, "time is not greater than given time");
       times = block.timestamp;
       return times;
    }

    function updateValue1() public {
       users[msg.sender].amount += 100;
    }

}