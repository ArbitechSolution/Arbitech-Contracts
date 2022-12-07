// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SimpleStakeUnStake{
    using SafeMath for uint256;
    struct userStruct{
        uint256 amount;
        uint256 time; 
    }

    // uint256 locktime = 60 seconds;
    address[] public stakeholders;
    mapping(address => userStruct) public stakes;    

    function isStaked(address _address)public view returns(bool,uint256){
        for(uint256 i=0 ;i<stakeholders.length; i++){
                if(_address==stakeholders[i]){
                    return (true,i);
                }
        }
                    return(false,0);
        }
    function removeStakeHolder(address _address) public{
        (,uint256 index)=isStaked(_address);
        stakeholders[index]=stakeholders[stakeholders.length-1];
        stakeholders.pop();
    }
    function stake() public payable returns(bool){
              require(msg.value >= 1 ether,"Invalid Value");
              (bool isAlreadyStaked,)=isStaked(msg.sender);
               if(!isAlreadyStaked){
                   stakeholders.push(msg.sender);  // Address
                   stakes[msg.sender].amount += msg.value; // Amount
                   stakes[msg.sender].time = block.timestamp;
               }
               return true;
              }
    
    function unstake() public payable {

        payable(msg.sender).transfer((stakes[msg.sender].amount)); 
        stakes[msg.sender].amount = 0;
         stakes[msg.sender].time = 0;
        removeStakeHolder(msg.sender);
        
    }

    function rewardCalc(address _address) public view returns(uint256){
        uint256 reward;
        // 
        if(block.timestamp>=stakes[_address].time+10 seconds){
          reward=stakes[_address].amount*2;
        }
        return reward;

    }
    function withdrawReward() public payable returns(bool) {
       
        uint256 _reward = rewardCalc(msg.sender);
         require(_reward>0,"No Reward Yet");
        payable(msg.sender).transfer(_reward);
        return true;
    }
    
}
