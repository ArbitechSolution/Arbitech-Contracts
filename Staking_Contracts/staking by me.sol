// SPDX-License-Identifier:MIT
pragma solidity ^0.8.15;

interface IERC20 {
    function balanceOf(address account) external view returns(uint256);
    function transfer(address receiver, uint256 tokenAmount) external  returns(bool);
    function transferFrom( address tokenOwner, address recipient, uint256 tokenAmount) external returns(bool);
}

interface IBEP20 {
    function balanceOf(address account) external view returns(uint256);
    function transfer(address receiver, uint256 tokenAmount) external  returns(bool);
    function transferFrom( address tokenOwner, address recipient, uint256 tokenAmount) external returns(bool);
}

contract Staking {

    IERC20 public token1;
    IBEP20 public token2;
    address public owner;
    address[] public stakeHolders;
    uint256 public receiveToken;
    // uint256 public rewardDuration = 1 days;

   
    constructor(IERC20 _stake, IBEP20 _Reward) {
        token1 = _stake;
        token2 = _Reward;
        owner = msg.sender;
    }

    struct userDetail {
        bool  isStaked;
        uint256 StakeTime;
        uint256 StakeAmount;
        uint256 Withdraw;
    }
    mapping(address => userDetail) public UserInfo;

    function isStake(address _user) public view returns(bool isStaked) {
        for(uint256 i = 0; i < stakeHolders.length; i++) {
            if(_user == stakeHolders[i]) {
                isStaked = true;
            } 
        }
    }

    function stake(uint256 _tokenAmount) public  {

        require(msg.sender != owner, "owner cannot stake!");
        if(isStake(msg.sender) != true ) {
            stakeHolders.push(msg.sender);  
        }
        else {
            UserInfo[msg.sender].StakeAmount += _tokenAmount;
        }
        UserInfo[msg.sender].isStaked = true; 
        UserInfo[msg.sender].StakeTime = block.timestamp;
        UserInfo[msg.sender].StakeAmount += _tokenAmount;
        token1.transferFrom( msg.sender, address(this), _tokenAmount ); 
        receiveToken += _tokenAmount;
    }

    function unStake(uint256 _index) public  returns(bool isUnstaked){
       uint256 amount = UserInfo[msg.sender].StakeAmount;
       for(uint256 i = _index ; i < stakeHolders.length - 1 ; i++) {
            stakeHolders[i] = stakeHolders[i + 1];
        }
        receiveToken -= amount;
        UserInfo[msg.sender].isStaked = false; 
        UserInfo[msg.sender].StakeTime = 0;
        UserInfo[msg.sender].StakeAmount = 0;
        token1.transfer(msg.sender, amount);
        stakeHolders.pop();
        return true;
    }
   
    function calculateReward(address _user) public view returns(uint256) {
        uint256 Reward;
        require(isStake(_user) == true, "not a staker");
        require(block.timestamp >= UserInfo[_user].StakeTime + 20 seconds, "time is not completed yet!");
        Reward = UserInfo[_user].StakeAmount * 5 ;
        return Reward;
    }

    function WithDraw() public returns(bool) {
        require(msg.sender != owner, "error");
        uint256 reward = calculateReward(msg.sender);
        token2.transferFrom(owner, msg.sender, reward); 
        UserInfo[msg.sender].Withdraw += reward;
        return true;
    }
  
    function DisplayLength() public view returns(uint256){
        return stakeHolders.length;
    }

  
   
}

