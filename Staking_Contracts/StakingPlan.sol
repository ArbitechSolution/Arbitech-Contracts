// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
// import "openzeppelin/contracts/utils/math/SafeMath.sol";
contract StakingPlan{
    // using SafeMath for uint256;
    struct userStruct{
        uint256 amount;
        uint256 time;
        uint256 package;
        uint256 reward;
    }
    mapping(address => userStruct) public balances;
    mapping (uint256 => uint256) public rewardRate ;
    constructor(){
         rewardRate[7] =  1200000000000000000; 
         rewardRate[10] = 1300000000000000000;
         rewardRate[15] = 1500000000000000000;
         rewardRate[20] = 1800000000000000000;
         rewardRate[30] = 2000000000000000000;
    }
    function Stake(uint256 _package) public payable {

        balances[msg.sender].amount = msg.value;
        balances[msg.sender].time = block.timestamp;
        balances[msg.sender].package = _package;
    }

    function rewardCalc(uint256 _amount) public view returns(uint256){
        uint256 reward = rewardRate[balances[msg.sender].package] * _amount;
        return reward;
    }


}
