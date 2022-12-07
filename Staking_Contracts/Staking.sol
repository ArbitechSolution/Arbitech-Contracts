// SPDX-License-Identifier:MIT
pragma solidity ^0.8.16;

interface IBEP20 {
    function balanceOf(address account) external view returns(uint256);
    function WithdrawStakingReward(uint256 _value) external    ;
    function getReward()external view returns(uint256);
    function transfer(address receiver, uint256 tokenAmount) external  returns(bool);
    function transferFrom( address tokenOwner, address recipient, uint256 tokenAmount) external returns(bool);
}

contract Staking {
   
    IBEP20 public token2;
    address[] public stakeHolders;
    address public owner;
    uint256 public lockTime = 3 minutes; 
    uint256 public rewardTokenPerDay = 20  ; 
    
    constructor(IBEP20 _Reward) {
        token2 = _Reward;
        owner = msg.sender;
    }
    
    struct userDetail {
        uint256 StakeTime;
        uint256 StakeAmount;
        uint256 Withdraw;
    }

    mapping(address => userDetail) public UserInfo;
    mapping(address => bool) public isStaked;
    mapping(address => uint256) public checkIndex;
    
    modifier onlyOwner{

      require  (msg.sender == owner," You are not Owner!");
        _;
    }
    
    modifier lockToken{

      require(block.timestamp >= UserInfo[msg.sender].StakeTime + lockTime , " lockTime!");
        _;
    }

    // function isStakeholder(address _user) public  view returns(bool isStake, uint256 index){
    //     for(uint256 i = 0; i < stakeHolders.length; i++){
    //         if (_user == stakeHolders[i]){
    //             return (isStake = true, index = i);
    //         }
    //         return (isStake = false,index = 0);
    //     }

    // }

    function stake() public payable{
     
        require(msg.sender != owner, "owner cannot stake!");
        require(!isStaked[msg.sender],"Unstake First");
        UserInfo[msg.sender].StakeAmount += msg.value;
        UserInfo[msg.sender].StakeTime = block.timestamp ;
        isStaked[msg.sender]=true;
        checkIndex[msg.sender] = stakeHolders.length;
        stakeHolders.push(msg.sender);
    }
    
    function unStake() public {

        UserInfo[msg.sender].StakeTime = 0;
        UserInfo[msg.sender].StakeAmount = 0;
        isStaked[msg.sender]=false;
        payable (msg.sender).transfer(UserInfo[msg.sender].StakeAmount);
        uint256 index ;
        index = checkIndex[msg.sender];
        for(uint256 i = index ; i < stakeHolders.length - 1 ; i++) {
            stakeHolders[i] = stakeHolders[i + 1];
        }
        // checkIndex[msg.sender] =stakeHolders.length -1;
        stakeHolders.pop();
        
    }

    function calculateReward(address _user) public view  returns(uint256) {
        
        uint256 Reward  ;
        uint256 totalTime = (block.timestamp - UserInfo[_user].StakeTime  ) / 5 seconds ;
        Reward = (((rewardTokenPerDay * 1 ether / 60 seconds )* totalTime) * UserInfo[_user].StakeAmount) / 1e18 ; 
        return Reward   ;   
                
    }

    function WithDraw() public  returns(bool successfullyWithdraw) {
        
        uint256 rewardX = calculateReward(msg.sender);
        token2.WithdrawStakingReward(rewardX) ;
        uint256 reward = getReward();
        UserInfo[msg.sender].Withdraw += reward ;
        return true;
    }

    function getReward()public view returns(uint256){

        return token2.getReward();
    }

    function getAddress() public view returns(address[] memory){
        return stakeHolders; 
    }

    function DisplayLength() public view returns(uint256){
        return stakeHolders.length;
    }
}

 