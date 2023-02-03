// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function _approve(address owner, address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721{
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getTokenIdInfo(uint256 tokenID) external view returns(uint256,uint256);
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

contract GemStaking{
    using SafeMath for uint256;
    IERC20 public Token;
    IERC721 public gemNft;

    uint256 public Stakers;
    uint256 gen1Score = 8;
    uint256 gen2Score = 7;
    uint256 gen3Score = 6;
    uint256 gen4Score = 5;
    uint256 gen5Score = 4;
    uint256 gen6Score = 3;
    uint256 gen7Score = 2;
    uint256 gen8Score = 1;

    uint256 sizeMultiplier = 1;
    uint256 public curCycle = 0;
    uint256 maxCycleTime = 10 minutes;
    uint256 public cycleSlots = 10;
    // uint256 cycleTime = 5 minutes;

    uint256 slotTime = 1 minutes;
    address public owner;

    struct StakedInfo{
        uint256 stakedScore;
        uint256 startTime;
        uint256 lastClaim;
        uint256 endTime;
        uint256 cycleStake;
        uint256 cyclePool;
    }

    struct cycleInfo{
        uint256 cycleNo;
        uint256 totalCycleScore;
        uint256 cycleStartTime;
        uint256 cycleEndTime;
    }

    mapping(address => StakedInfo) public userInfo;
    mapping(uint256 => cycleInfo) public cycles;
    mapping(address => uint256) public claimedReward;
    mapping(uint256 => uint256 ) public poolReward;


    constructor() {
        gemNft = IERC721(0xc153f0DAaA7f371528650338f415d631b189c8cB);
        Token = IERC20(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        owner = msg.sender;

        cycles[curCycle].cycleStartTime = block.timestamp;
        cycles[curCycle].cycleEndTime = (block.timestamp).add(maxCycleTime);
    }
    modifier onlyOwner{
        require(owner == msg.sender, "caller is not the owner!!");
        _;
    }

    // function StakeGem(uint256 tokenId) public{
    function StakeGem(uint256 generation, uint256 size) public{
        StakedInfo storage user = userInfo[msg.sender];
        require(user.startTime == 0, "User Already Staked!!");
        // (uint256 generation, uint256 size) = gemNft.getTokenIdInfo(tokenId);
        uint256 userScore = getUserStakedScore(generation,size);
        // gemNft.transferFrom(msg.sender,address(this),tokenId);
        user.stakedScore = userScore;
        user.startTime = block.timestamp;
        user.endTime = (block.timestamp).add(maxCycleTime);
        user.cycleStake = curCycle;
        user.cyclePool = poolReward[curCycle];

        // if(cycles[curCycle].cycleEndTime > 0)
        updateCycle();
        // cycles[curCycle].cycleStartTime = block.timestamp;
        // cycles[curCycle].cycleEndTime = (block.timestamp).add(maxCycleTime);
        cycles[curCycle].totalCycleScore += userScore;

        Stakers = Stakers.add(1);
    }

    function getUserStakedScore(uint256 generation, uint256 size) public view returns(uint256){
        uint256 size_ = size.mul(sizeMultiplier);
        uint256 userScore;
        if(generation == 1){ userScore = (gen1Score).add(size_); }
        else if(generation == 2){ userScore = (gen2Score).add(size_); }
        else if(generation == 3){ userScore = (gen3Score).add(size_); }
        else if(generation == 4){ userScore = (gen4Score).add(size_); }
        else if(generation == 5){ userScore = (gen5Score).add(size_); }
        else if(generation == 6){ userScore = (gen6Score).add(size_); }
        else if(generation == 7){ userScore = (gen7Score).add(size_); }
        else if(generation == 8){ userScore = (gen8Score).add(size_); }
        return userScore;
    }

    function getTime(address _user) public view returns(uint256){
        StakedInfo storage user = userInfo[_user];
    
        uint256 time =0;
        time = block.timestamp.sub(user.startTime).div(slotTime);
        return time;
    }

    function cycleReward (address _user,uint256  _time) public view returns(uint256){
        StakedInfo storage user = userInfo[_user];
        uint256 cycleDiff = curCycle.sub(user.cycleStake);
        uint256 userEarn;
        uint256 cycleTime;
        uint256 reward;
        uint256 cycleInc;
        for(uint256 i; i< cycleDiff; i++){
            cycleInc++;
            uint256 cycleScore = cycles[(user.cycleStake) + cycleInc].totalCycleScore;
            cycleTime = (_time.mul(60)).sub(cycles[(user.cycleStake) + 1].cycleStartTime);

            userEarn = ((poolReward[(user.cycleStake)+cycleInc]).div(cycleScore)).mul((user.stakedScore));
            reward += (userEarn).div(cycleSlots).mul(cycleTime);
        }
        return reward;
    }

    function stakeTime(address _user, uint256 userCycle) public view returns(uint256){
        StakedInfo storage user = userInfo[_user];
        uint256 timeDiff = (cycles[userCycle].cycleEndTime).sub(user.startTime);
        return timeDiff;
    }

    function userReward(address _user) public view returns(uint256){
        StakedInfo storage user = userInfo[_user];
        uint256 time = getTime(_user);
        uint256 reward;
        uint256 userCycle = user.cycleStake;
        uint256 userStakeTime = stakeTime(_user, userCycle);
        uint256 totalScore = cycles[userCycle].totalCycleScore;
        uint256 userEarn = ((user.cyclePool).div(totalScore)).mul((user.stakedScore));
        uint256 nextReward = cycleReward(_user,time);

        if(time >= cycleSlots){
            time = cycleSlots;
        }

        reward = ((userEarn).div(cycleSlots)).mul(time);
        reward += (reward.div(userStakeTime)).mul(100);
        reward = reward.add(nextReward);
        return reward.sub(claimedReward[_user]);
    }

    function claimReward() public {
        require(block.timestamp >= cycles[(curCycle + 1)-1].cycleEndTime, "claim time not completed!!");
        require(block.timestamp >= userInfo[msg.sender].endTime, "claim time not completed!!");
        uint256 userReward_ = userReward(msg.sender);

        claimedReward[msg.sender] += userReward_;
        // Token.transfer(msg.sender, userReward_);
    }

    function unStakeGem(uint256 tokenId) public{
        require(block.timestamp >= userInfo[msg.sender].endTime, "Unstake time not reached!!");
        claimReward();
        StakedInfo storage user = userInfo[msg.sender];
        // gemNft.transferFrom(address(this),msg.sender,tokenId);
        user.startTime = 0;
        user.endTime = 0;
        Stakers = Stakers.sub(1);
    }

    function updateCycle() public {
        if(block.timestamp > cycles[curCycle].cycleEndTime){
            curCycle++;
            cycles[curCycle].cycleNo = curCycle;
            cycles[curCycle].totalCycleScore = cycles[curCycle-1].totalCycleScore;

            cycles[curCycle].cycleStartTime = block.timestamp;
            cycles[curCycle].cycleEndTime = block.timestamp.add(maxCycleTime);
        }
    }

    function getinfo(uint256 tokenID) public view returns(uint256,uint256){
        return gemNft.getTokenIdInfo(tokenID);
    }

    
    function setPoolReward(uint256 _poolReward) public onlyOwner{
        updateCycle();
        poolReward[curCycle] = _poolReward;
    }

}


/*

    function stakeTimeReward(address _user) public view returns(uint256){
        StakedInfo storage user = userInfo[_user];
        uint256 userCycle = user.cycleStake;

        uint256 _cycleTime = ((cycles[userCycle].cycleEndTime).sub(user.startTime)).div(60);
        uint256 cycleRew;
        uint256 totalTimeReward;

        uint256 totalScore = cycles[userCycle].totalCycleScore;
        uint256 userEarn = (user.stakedScore).div(user.stakedScore);
        
        // uint256 userEarn = ((poolReward).div(totalScore)).mul((user.stakedScore));

        // cycleRew = (user.stakedScore).div(maxCycleTime);
        // totalTimeReward = (cycleRew).mul(_cycleTime).mul(60);

        if(user.lastClaim == 0){
            uint256 time__ = curCycle.sub(userCycle);
            // uint256 nextRew;
            for(uint256 i =1; i<= time__; i++){
                totalTimeReward += (cycles[userCycle+i].totalCycleScore).div(user.stakedScore);
                // nextRew += (user.stakedScore).div(maxCycleTime);
            }

        }

        return totalTimeReward;
    }
    =>  
        // uint256 _reward = stakeTimeReward(_user);
        // uint256 userReward_ = ((user.stakedScore).mul(100)).div(poolReward);
        // reward += ((userReward_).mul(time)).div(maxCycleTime);
        // uint256 totalScore = cycles[curCycle].totalCycleScore;
*/