// SPDX-License-Identifier:MIT
pragma solidity 0.8.13;

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Staking{

using SafeMath for uint256;
struct myStruct{
    uint256 amount;
    uint256 time;
}

bool  isStake;
mapping(address=>myStruct) public stakes;

function stake() public payable returns(bool){
require(msg.value >= 1 ether, "invalid value");

     //stakeHolder.push(msg.sender);
     stakes[msg.sender].amount += msg.value; 
     stakes[msg.sender].time = block.timestamp;
    return true;
}

function calculateReward(address _addr) public view returns(uint256){
    uint256 reward;
    if(block.timestamp >= stakes[_addr].time +10 seconds){
        reward = stakes[_addr].amount.mul(2);
    }
    return reward;
}
}

