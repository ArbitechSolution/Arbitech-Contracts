// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


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

interface IReward{
    function withDrawReward(address _addrs, uint256 _amount) external;
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract tokenStaking{

    IReward _RewToken;
    address public Owner;

    constructor(IReward rewToken) {
        _RewToken = rewToken;
        Owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == Owner,"not an Owner");
        _;
    }

    using SafeMath for uint256;

    uint256 public endTime = 30 seconds;
    uint256 public timeSlot = 4 seconds;
    
    address[] private addrs;

    struct USER{
        uint256 stakeAmt;
        uint256 stakeTime;
    }

    mapping (address => USER) public usersStake;
    mapping(address => bool) public Staked;

    function Stake(uint256 _amount) public {
        usersStake[msg.sender].stakeAmt = _amount;
        usersStake[msg.sender].stakeTime = block.timestamp;
        _RewToken.transferFrom(msg.sender,address(this),_amount);

        Staked[msg.sender] = true;
        addrs.push(msg.sender);
    }

    // function setArray() public onlyOwner {
    //     address[] memory adrs = getArray();
    //     _RewToken.setArray(adrs);
    // }

    function getArray() public view returns(address[] memory){
        return addrs;
    }

    function checkReward() public view returns(uint256){
        require(block.timestamp > usersStake[msg.sender].stakeTime);
        uint256 timeDiff = block.timestamp - usersStake[msg.sender].stakeTime;
        uint256 Rew;
        
        if(timeDiff < endTime){
            Rew = timeDiff.div(timeSlot).mul(usersStake[msg.sender].stakeAmt.mul(3).div(100));
            // Rew = Rew *timeDiff;
            // uint256 totalRew = Rew + usersStake[msg.sender].stakeAmt;
            return Rew;
        }
        else{
            Rew = usersStake[msg.sender].stakeAmt.mul(8).div(100);
            return Rew;
        }
        // uint256 totalRew = usersStake[msg.sender].stakeAmt* rewardAmt;
        // uint256 deduction = totalRew - (totalRew/100*2);
        // return deduction;
    }
    // modifier isStaked{
    //     require(Staked[msg.sender] == true, "Not staker");
    //     _;
    // }

    function withDrawReward() public {
        uint256 calcRewards = checkReward();
        _RewToken.withDrawReward(msg.sender, calcRewards);
    }

}