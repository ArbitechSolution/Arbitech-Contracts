// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IERC20{
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

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

contract StakeUnStake{
    
    using SafeMath for uint256;
    address public Owner;
    IERC20 _iStake;
    IERC20 _iReward;

    uint256 public finaltime = 2 minutes;
    uint256 public time = 30;

    constructor(IERC20 _stake, IERC20 _reward){
        Owner = msg.sender;
        _iStake = _stake;
        _iReward = _reward;
    }

    struct Staker{
        uint256 amount;
        uint256 time;
        uint256 calculatedReward;
        uint256 withdraww;
    }

    mapping (address => Staker) public userStake;
      
   function Staking(uint256 _amount) public {
       _iStake.transferFrom(msg.sender, address(this), _amount);
       userStake[msg.sender].amount = _amount;
       userStake[msg.sender].time = block.timestamp;
   }
    
    function checkReward() public view returns(uint256) {
        uint256 Reward;
        
        uint256 endTime = userStake[msg.sender].time + finaltime;
        if (block.timestamp >= endTime){
           Reward = (userStake[msg.sender].amount).mul(8).div(100);
        }else{
            Reward = block.timestamp.sub(userStake[msg.sender].time).div(time).mul(userStake[msg.sender].amount).mul(2).div(100);
        }
        return Reward;
    }

    function withDrawReward() public returns(uint256) {
        uint256 _Reward = checkReward();
        _iReward.transferFrom( address(this), msg.sender, _Reward);
        return _Reward;  
    }

    function unStake() public {
        require(msg.sender != address(0), "must be an address");
        userStake[msg.sender].amount = 0;
    }
}


    // ARBI.transferfrom(msg.sender,address(this),2500);
    // Usdt.transferfrom(msg.sender,address(this),2500);


    //   function get() public view returns(uint256){
    //         return userStake[msg.sender].calculatedReward;
    //   } 

    // if(Reward != 0){
    //     Reward = userStake[msg.sender].calculatedReward - Reward;
    // }
    // _iStake.transfer(payable(msg.sender), _Reward);


    // ------------- Conditions -----------

    // userStake[msg.sender].calculatedReward += _Reward;
    // if(userStake[msg.sender].calculatedReward != 0){

    // if(_Reward != 0){
    //     return _Reward;
    // }
    
    // else{
    //     _Reward -= userStake[msg.sender].calculatedReward;
    //     return _Reward;
    // }

        
    // function changeTime(uint256 _seconds) public {
    //     // endTime = _seconds;
    // }
    // function temp() external pure returns(uint256){
    //     uint256 result = (60).div(30));
    //     return result ;
    // }
    // uint256 totalSlots= block.timestamp.sub(userStake[msg.sender].time).div(time);
