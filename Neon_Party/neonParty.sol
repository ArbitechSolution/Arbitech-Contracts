// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SafeMath {
    
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract neonParty is Ownable{

    using SafeMath for uint256;
    address public defaultRefer;
    uint256 public referDepth = 10;
    uint256 public totalUser;

    uint256 public minDeposit = 500 ether;
    uint256 public maxDeposit = 8000 ether;

    // uint256 public contractBillionBalance = 1_000_000_000*10**18;  // 1 billion
    uint256 public contractBillionBalance = 150*10**18;  // 1 billion
    uint256 public curBillionBalance = contractBillionBalance;

    // uint256 contractMillionBalance = 8000000*(10**18);   // 8 million
    uint256 contractMillionBalance = 100*(10**18);   // 8 million
    uint256 public curMillionBalance = contractMillionBalance;

    uint256 public maxIncome = 3;    // 3 %
    uint256 public curTotalDept;
    uint256 public startTime;
    uint256 public timeStamp = 1 minutes;
    // uint256 dayslots = 1440;
    uint256 public dayslots = 10;
    uint256 public dayDiff = 1 days;   //  bonusTime

    uint256 public baseDivider = 10000;

    uint256 public minDailyBonus = 10;
    uint256 finalTime = dayslots.mul(10);

    uint256 public dailyPercentage = 100;

    uint256 public billionPercentage = 20;  // 0.2%
    uint256 public curBillionPercents = billionPercentage;

    uint256 public millionPercentage = 10;  // 0.1%
    uint256 public curMillionPercents = millionPercentage;

    uint256 public referrelCommission = 10;
    uint256 public curCommission = referrelCommission;

    uint256[10] public levelsIncomePercents = [800, 400, 300, 150, 50, 30, 20, 20, 20, 10];

    address[] public depositers;
    address[] public referrals;

    struct UserInfo{
        address referrer;
        uint256 depositTime;
        uint256 lastClaim;
        uint256 totalDeposit;
        uint256 teamNum;
    }

    struct OrderInfo {
        uint256 amount; 
        uint256 start;
    }

    struct RewardInfo{
        uint256 previousRew;
        // uint256 curReward;
        uint256 billRew;
        uint256 millRew;
        uint256 bonusRew;
        uint256 claimedReward;
        uint256 claimedReward1;
        uint256 levelIncome;
        uint256 refIncome;
        uint256 totalWithdrawl;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(address => RewardInfo) public rewardInfo;
    mapping(address => OrderInfo[]) public orderInfos;
    mapping(address => mapping(uint256 => address[])) public teamUsers;    

    event Register(address indexed _caller, address indexed _referral);
    constructor() {
        startTime = block.timestamp;
        // lastDistribute = block.timestamp;
        defaultRefer = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    }

    function register(address _referral) external {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        // directUsers[_referral].push(msg.sender);
        // user.start = block.timestamp;
        user.depositTime = block.timestamp;
        _updateTeamNum(msg.sender);
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }

    function checkDepositers(address _address) public view returns(bool,uint256)
    {
        for (uint256 i = 0; i < depositers.length; i++){
            if (_address == depositers[i]){
            return (true,i);
            } 
        }
        return (false,0);
    }
    function checkReferrals(address _address) public view returns(bool,uint256)
    {
        for (uint256 i = 0; i < referrals.length; i++){
            if (_address == referrals[i]){
            return (true,i);
            } 
        }
        return (false,0);
    }

    function deposit() public payable {
        require(msg.value > 0, "low amount");
        uint256 _amount = msg.value;
        _deposit(msg.sender, _amount);
    }

    function _deposit(address _user, uint256 _amount) private {
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0), "register first");
        // require(_amount >= minDeposit, "less than min");
        // require(_amount <= maxDeposit, "greater than max");
        // require(_amount.mod(minDeposit) == 0 && _amount >= minDeposit, "mod err");
        // require((user.totalDeposit).add(_amount) <= maxDeposit,"should be less");

        uint256 prevRew = userReward(_user);
        (bool _isDepAvailable,) = checkDepositers(_user);
        (bool _isRefAvailable,) = checkReferrals(user.referrer);
        RewardInfo storage user_ = rewardInfo[_user];
        user_.previousRew = (user_.previousRew).add(prevRew);

        user.totalDeposit += _amount; 
        curTotalDept = curTotalDept.add(_amount);
        user.depositTime = block.timestamp;

        orderInfos[_user].push(OrderInfo(
            _amount, 
            block.timestamp
        ));

        if(!_isDepAvailable)
        {   depositers.push(_user);   }

        if(!_isRefAvailable)
        {   referrals.push(user.referrer);    }

        updateLevelIncome(_amount);
        billionReward();
        millionReward();
        user.lastClaim = block.timestamp;
    }

    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function billionReward() public{
        uint256 deptPercents;
        uint256 singleRew;
        
        if(curTotalDept >= curBillionBalance){
            deptPercents = (curTotalDept.mul(curBillionPercents)).div(baseDivider);
            singleRew = deptPercents.div(depositers.length);
            for(uint256 i; i< depositers.length; i++){
                RewardInfo storage userRew = rewardInfo[depositers[i]];
                userRew.billRew = (userRew.billRew).add(singleRew);
            }

            curBillionBalance = curBillionBalance.add(contractBillionBalance);
            curBillionPercents = curBillionPercents.add(billionPercentage);
            
            if(curBillionPercents > 100){
                curBillionPercents = billionPercentage;
            }
            extraBonus();
        }
    }

    function extraBonus() public{

        uint256 refPercents;
        uint256 singleRew;
        refPercents = (curTotalDept.mul(curCommission)).div(baseDivider);
        singleRew = refPercents.div(referrals.length);
        for(uint256 i; i< referrals.length; i++){
            RewardInfo storage userRew = rewardInfo[referrals[i]];
            userRew.refIncome = (userRew.refIncome).add(singleRew);
        }
        curCommission = curCommission.add(referrelCommission);
        if(curCommission>50){
            curCommission = referrelCommission;
        }
    }

    //  community incentive
    function millionReward() public{
        uint256 deptPercents;
        uint256 singleRew;

        if(curTotalDept >= curMillionBalance){
            deptPercents = (curTotalDept.mul(curMillionPercents)).div(baseDivider);
            singleRew = deptPercents.div(depositers.length);
            for(uint256 i; i< depositers.length; i++){
                RewardInfo storage userRew = rewardInfo[depositers[i]];
                userRew.millRew = (userRew.millRew).add(singleRew);
            }

            curMillionBalance = curMillionBalance.add(contractMillionBalance);
            curMillionPercents = curMillionPercents.add(millionPercentage);

            if(curMillionPercents > 50){   // 50 => 0.5%
                curMillionPercents = millionPercentage;
            }
        }
    }

    function userRewardTime(address _user) public view returns(uint256){
        uint256 _time = ((block.timestamp).sub(userInfo[_user].depositTime)).div(timeStamp);
        return _time;
    }
    function userReward(address _user) public view returns(uint256){
        UserInfo storage user = userInfo[_user];
        uint256 userDep = user.totalDeposit;
        uint256 _time = userRewardTime(_user);

        uint256 _dayreward = (userDep.mul(dailyPercentage)).div(baseDivider);
        _dayreward = ((_dayreward).div(dayslots)).mul(_time);
        if(_dayreward > 0)
        { _dayreward =  (_dayreward.sub(rewardInfo[_user].claimedReward)).sub(rewardInfo[_user].claimedReward1);   }
        else 
        {    _dayreward =0;   }
        
        return _dayreward;
    }

    function bonusTime(address _user) public view returns(uint256){
        uint256 _time;

        if(userInfo[_user].lastClaim > 0){
            _time = (block.timestamp.sub(userInfo[_user].lastClaim)).div(timeStamp);
        }
        return _time;
    }
    function bonuPercentage(address _user) public view returns(uint256){
        uint256 rewardPercent;
        uint256 _dayReward;
        rewardPercent = ((userInfo[_user].totalDeposit).mul(minDailyBonus)).div(baseDivider);
        _dayReward = rewardPercent.div(dayslots);
        return _dayReward;
    }

    function bonusReward(address _user)public view returns(uint256) {

        uint256 _dayReward;
        uint256 count = 0;
        uint256 totalTime;
        uint256 _time ;
        uint256 reward;
        uint256 count1;

        if((userInfo[_user].lastClaim) > 0){
            if((block.timestamp) >= ((userInfo[_user].lastClaim).add(5 minutes))){ // dayDiff

                _time = bonusTime(_user);
                _dayReward = bonuPercentage(_user);
                reward = _dayReward.mul(_time);
                totalTime = _time;
                while(_time > finalTime){
                    count++;
                    count1 = count.mul(dayslots);
                    _time = totalTime.sub(count1);
                    reward = _time.mul(_dayReward);
                }
            }
        }
            
        return reward;
    }

    function userTotalReward(address _user) public view returns(uint256, uint256, uint256, bool,uint256, uint256){
        RewardInfo storage userRew = rewardInfo[_user];
        // UserInfo storage user = userInfo[_user];
        uint256 userFinalRew;
        bool maxApproached;
        // uint256 userMaxRew = user.totalDeposit.mul(maxIncome);

        uint256 userMaxRew = 5 ether;  //  testing
        uint256 _bonusRew = bonusReward(_user);
        uint256 _reward = userReward(_user);
        uint256 reward_1;
        uint256 reward_2;
        reward_1 = (userRew.claimedReward).add(userRew.millRew).add(userRew.billRew).add(userRew.refIncome).add(userRew.bonusRew);
        reward_2 = (_reward).add(userRew.totalWithdrawl).add(userRew.levelIncome).add(userRew.previousRew).add(_bonusRew);

        userFinalRew = reward_1.add(reward_2);
        if(userFinalRew >= userMaxRew){
            userFinalRew = userMaxRew;
            maxApproached = true;
        }

        userFinalRew = userFinalRew.sub(userRew.totalWithdrawl);
        return (userFinalRew, _reward, _bonusRew, maxApproached, userRew.claimedReward, reward_2);
    }

    function claimReward() public {
        RewardInfo storage userRew = rewardInfo[msg.sender];
        UserInfo storage user = userInfo[msg.sender];
        uint256 _bonusRew = bonusReward(msg.sender);
        uint256 regRewards = userReward(msg.sender);
        userRew.bonusRew = userRew.bonusRew.add(_bonusRew);
        userRew.claimedReward = (userRew.claimedReward).add(regRewards);
        user.lastClaim = block.timestamp;
    }

    function withdraw() public {
        RewardInfo storage userRew = rewardInfo[msg.sender];
        UserInfo storage user = userInfo[msg.sender];
        // claimReward();
        // (uint256 finalReward,,, bool maxApproached,,) = userTotalReward(msg.sender);
        (uint256 finalReward, uint256 regRewards,, bool maxApproached, uint256 claimedward,) = userTotalReward(msg.sender);

        userRew.claimedReward1 = userRew.claimedReward1.add(claimedward.add(regRewards));
        userRew.totalWithdrawl = (userRew.totalWithdrawl).add(finalReward);
        userRew.claimedReward = 0;
        userRew.millRew = 0;
        userRew.billRew = 0;
        userRew.bonusRew = 0;
        userRew.previousRew = 0;
        userRew.levelIncome = 0;
        userRew.refIncome = 0;

        user.lastClaim = block.timestamp;
        if(maxApproached)
        {
            user.lastClaim =0;  
            user.totalDeposit = 0;
            userRew.claimedReward = 0;
        }
        payable(msg.sender).transfer(finalReward);
    }

    function updateLevelIncome(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];

        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint i = 0; i < referDepth; i++) {
                if (upline != address(0)) {
                    uint amount = _amount.mul(levelsIncomePercents[i]).div(baseDivider);

                    if (amount > 0) {
                        rewardInfo[upline].levelIncome = rewardInfo[upline].levelIncome.add(amount);
                    }
                    upline = userInfo[upline].referrer;
                } else break;
            }

        }
    }

    function getDepositersLength() public view returns(address[] memory){
        return depositers;
    }
    function getReflength() public view returns(address[] memory){
        return referrals;
    }

    function changeBillionPercents(uint256 _percents) public onlyOwner{
        billionPercentage = _percents;
    }
    function changeMillionPercents(uint256 _percents) public onlyOwner{
        millionPercentage = _percents;
    }
    function changeReferrelPercents(uint256 _percents) public onlyOwner{
        referrelCommission = _percents;
    }

}