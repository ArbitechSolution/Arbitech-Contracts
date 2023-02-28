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
    address public devAddress;
    address public charityAddress;
    address public marketer;
    address public globalLeaderAddress;

    uint256 public marketingFunds = 500;  // 5%
    uint256 public globalLeader = 300;   //  3%
    uint256 public charityfunds = 200;  // 2%
    uint256 public devFunds = 500;   // 5%

    uint256 public referDepth = 10;
    uint256 public totalUser;
    uint256 public minDeposit = 500e6;
    uint256 public maxDeposit = 8000e6;

    uint256 public maxIncome = 3;    // 3 %
    uint256 public curTotalDept;
    uint256 public timeStamp = 1 minutes;
    // uint256 dayslots = 1440;
    uint256 public dayslots = 10;
    uint256 public dayDiff = 1 days;   //  bonusTime

    uint256 public baseDivider = 10000;

    uint256 public minDailyBonus = 10;
    uint256 finalTime = dayslots.mul(10);

    uint256 public dailyPercentage = 260;

    uint256[10] public referralPercents = [800, 400, 300, 150, 50, 30, 20, 20, 20, 10];

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
    
    //  TJHYbk7q2EuMJJZeEF6cxPBEDg9kG1sR1j, TWAY8fGTBHfWwsXLwnSsd5oh5ZrRqWusne, 
    //  TJ1WCZPs1PJP2q368UKEdsWiYdz9GT43vj, TGowyTywdUG97ynWMrX2QYa5hJGxhooian, TBqKMWLLryq6tu23owfQgTFaVs91H3maj4

    constructor
    (
        address _defaultRefer,
        address _devAddress,
        address _marketer,
        address _globalLeaderAddress,
        address _charityAddress
    ) 
    {
        defaultRefer = _defaultRefer;
        devAddress = _devAddress;
        marketer = _marketer;
        globalLeaderAddress = _globalLeaderAddress;
        charityAddress = _charityAddress;
    }
    
    function register(address _referral) external{
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
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
    
    
    function updateLevelIncome(uint256 _amount) public{
        UserInfo storage user = userInfo[msg.sender];

        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint i = 0; i < referDepth; i++) {
                if (upline != address(0)) {
                    uint amount = _amount.mul(referralPercents[i]).div(baseDivider);

                    if (amount > 0) {
                        rewardInfo[upline].levelIncome = rewardInfo[upline].levelIncome.add(amount);
                    }
                    upline = userInfo[upline].referrer;
                } else break;
            }

        }
    }

    function deposit() public payable{
        require(msg.value > 0, "low amount");
        uint256 _amount = msg.value;
        _deposit(msg.sender, _amount);
    }

    function _deposit(address _user, uint256 _amount) private{
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
        distributeFunds(_amount);
        user.lastClaim = block.timestamp;
    }

    function distributeFunds(uint256 _amount) public{
        distributeMarketingFunds(_amount);
        distributeProjectFunds(_amount);
        distributeCharityFunds(_amount);
        distributeDevFunds(_amount);
    }
    function distributeMarketingFunds(uint256 _amount) public{
        uint256 percents = (_amount.mul(marketingFunds)).div(baseDivider);  // 5%
        payable(marketer).transfer(percents);
    }
    function distributeProjectFunds(uint256 _amount) public{
        uint256 percents = (_amount.mul(globalLeader)).div(baseDivider);  // 3%
        payable(globalLeaderAddress).transfer(percents);
    }
    function distributeCharityFunds(uint256 _amount) public{
        uint256 percents = (_amount.mul(charityfunds)).div(baseDivider);  // 2%
        payable(charityAddress).transfer(percents);
    }
    function distributeDevFunds(uint256 _amount) public{
        uint256 percents = (_amount.mul(devFunds)).div(baseDivider);  // 5%
        payable(devAddress).transfer(percents);
    }
    

    function _updateTeamNum(address _user) private{
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
    
      
    // uint256[] public balanceArray = 
    // [1000000000e6, 2000000000e6, 3000000000e6, 4000000000e6, 500000000e6];
    
    uint256[] public balanceArray = [10e6, 20e6, 30e6, 40e6, 50e6];   //  testing
    uint256[] public millPercents = [20, 40, 60, 80, 100];

    function newBillReward() public view returns(uint256){
        uint256 deptPercents;

        for(uint256 i; i< balanceArray.length; i++){
            if(curTotalDept >= balanceArray[i]){
                deptPercents = (curTotalDept.mul(millPercents[i])).div(baseDivider);
            }
        }
        // extraBonus();
        return deptPercents;
    }
    
    // uint256[] public ActiveUsers = [800, 1600, 2400, 3200, 4000];
    uint256[] public ActiveUsers = [1, 2, 3, 4, 5];   //   testing
    uint256[] public userPercents = [10, 20, 30, 40, 50];
    
    function newActiveUserReward() public view returns(uint256){
        uint256 deptPercents;
        uint256 size = getDepositersLength();
        for(uint256 i; i< ActiveUsers.length; i++){
            if(size >= ActiveUsers[i]){
                deptPercents = (curTotalDept.mul(userPercents[i])).div(baseDivider);
            }
        }
        return deptPercents;
    }
    
    uint256[] public extraPercents = [10, 20, 30, 40, 50];

    function extraBonus() public view returns(uint256){
        uint256 refPercents;
        for(uint256 i; i< depositers.length; i++){
            if(curTotalDept >= balanceArray[i]){
                refPercents = (curTotalDept.mul(extraPercents[i])).div(baseDivider);
            }
        }
        return refPercents;
    }

    function userRewardTime(address _user) public view returns(uint256){
        uint256 _time = ((block.timestamp).sub(userInfo[_user].depositTime)).div(timeStamp);
        return _time;
    }
    function userReward(address _user) public view returns(uint256){
        UserInfo storage user = userInfo[_user];
        uint256 userDep = user.totalDeposit;
        uint256 _time = userRewardTime(_user);
        
        uint256 totalPercents = dailyPercentage.add(newBillReward().add(newActiveUserReward().add(extraBonus())));
        
        uint256 _dayreward = (userDep.mul(totalPercents)).div(baseDivider);
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

    function bonusReward(address _user)public view returns(uint256){

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

        uint256 userMaxRew = 5 trx;  //  testing
        uint256 _bonusRew = bonusReward(_user);
        uint256 _reward = userReward(_user);
        uint256 reward_1;
        uint256 reward_2;
        reward_1 = (userRew.claimedReward).add(newActiveUserReward()).add(newBillReward()).add(userRew.refIncome).add(userRew.previousRew); // .add(userRew.bonusRew) => removed
        reward_2 = (_reward).add(userRew.totalWithdrawl).add(userRew.levelIncome).add(userRew.previousRew).add(_bonusRew);

        userFinalRew = reward_1.add(reward_2);
        if(userFinalRew >= userMaxRew){
            userFinalRew = userMaxRew;
            maxApproached = true;
        }

        userFinalRew = userFinalRew.sub(userRew.totalWithdrawl);
        return (userFinalRew, _reward, _bonusRew, maxApproached, userRew.claimedReward, newBillReward());
    }

    function claimReward() public{
        RewardInfo storage userRew = rewardInfo[msg.sender];
        UserInfo storage user = userInfo[msg.sender];
        (uint256 totalReward,,,,,)  = userTotalReward(msg.sender);
        userRew.claimedReward = (userRew.claimedReward).add(totalReward);
        user.lastClaim = block.timestamp;
    }

    function withdraw() public{
        RewardInfo storage userRew = rewardInfo[msg.sender];
        UserInfo storage user = userInfo[msg.sender];
        (uint256 finalReward,,, bool maxApproached,,) = userTotalReward(msg.sender);
        userRew.claimedReward = 0;
        // userRew.bonusRew = 0;
        userRew.previousRew = 0;
        userRew.levelIncome = 0;
        userRew.refIncome = 0;

        userRew.totalWithdrawl = (userRew.totalWithdrawl).add(finalReward);
        user.lastClaim = block.timestamp;
        if(maxApproached)
        {
            user.lastClaim =0;  
            user.totalDeposit = 0;
            userRew.claimedReward = 0;
        }
        curTotalDept = curTotalDept.sub(finalReward);
        payable(msg.sender).transfer(finalReward);
    }


    function getDepositersLength() public view returns(uint256){
        return depositers.length;
    }
    function getReflength() public view returns(uint256){
        return referrals.length;
    }

    
    function changeFundsPercents
    (
        uint256 _marketingFunds,
        uint256 _globalLeader, 
        uint256 _charityfunds, 
        uint256 _devFunds
    )
    public onlyOwner
    {
        marketingFunds = _marketingFunds;
        globalLeader = _globalLeader;
        charityfunds = _charityfunds;
        devFunds = _devFunds;
    }
    
    function ownerWithdraw() public onlyOwner{
        curTotalDept = curTotalDept.sub(address(this).balance);
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }
    
    function getCurbalance() public view returns(uint256 _curTotalDept){
        _curTotalDept = curTotalDept.sub(address(this).balance);
    }
    
}
