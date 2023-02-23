// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Neon_Party is Ownable {
    using SafeMath for uint256;
    address public defaultRefer;
    uint256 public referDepth = 10;
    uint256 public totalUser;

    uint256 public minDeposit = 500e6;
    uint256 public maxDeposit = 8000e6;

    // uint256 public contractBillionBalance = 1_000_000_000*10**6;  // 1 billion
    uint256 public contractBillionBalance = 5000 * 10**6; // 1 billion
    uint256 public curBillionBalance = contractBillionBalance;

    // uint256 contractMillionBalance = 8000000*(10**6);   // 8 million
    uint256 contractMillionBalance = 2000 * (10**6); // 8 million
    uint256 public curMillionBalance = contractMillionBalance;

    uint256 public maxIncome = 3; // 3 %
    uint256 public curTotalDept;
    uint256 public startTime;
    uint256 public timeStamp = 1 minutes;
    // uint256 dayslots = 1440;
    uint256 dayslots = 10;
    uint256 public dayDiff = 1 days; // bonusReward lock time

    uint256 public baseDivider = 10000;

    uint256 public minDailyBonus = 10;
    uint256 finalTime = dayslots.mul(10);

    uint256 public dailyPercentage = 100;

    uint256 public billionPercentage = 20; // 0.2%
    uint256 public curBillionPercents = billionPercentage;

    uint256 public millionPercentage = 10; // 0.1%
    uint256 public curMillionPercents = millionPercentage;

    uint256 public referrelCommission = 10;
    uint256 public curCommission = referrelCommission;

    uint256[10] public levelsIncomePercents = [
        800,
        400,
        300,
        150,
        50,
        30,
        20,
        20,
        20,
        10
    ];

    address[] public depositers;
    address[] public referrals;

    struct UserInfo {
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

    struct RewardInfo {
        uint256 dayReward;
        uint256 previousRew;
        uint256 curReward;
        // uint256 totalReward;
        uint256 billRew;
        uint256 millRew;
        uint256 bonusRew;
        uint256 levelIncome;
        uint256 refIncome;
        uint256 totalWithdrawl;
    }

    mapping(address => bool) public isExist;
    mapping(address => UserInfo) public userInfo;
    mapping(address => RewardInfo) public rewardInfo;
    mapping(address => OrderInfo[]) public orderInfos;
    mapping(address => address[]) public refAddresses;
    mapping(address => uint256) public withdrawedReward;
    mapping(address => mapping(uint256 => address[])) public teamUsers;

    event Register(address indexed _caller, address indexed _referral);

    constructor(address _defaultRefer) {
        startTime = block.timestamp;
        defaultRefer = _defaultRefer;
    }

    function register(address _referral) external {
        require(
            userInfo[_referral].totalDeposit > 0 || _referral == defaultRefer,
            "invalid refer"
        );
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
        // require((user.totalDeposit).add(_amount) <= maxDeposit,"amount should be less");

        uint256 prevRew = userReward(_user);

        RewardInfo storage userRewardInfo = rewardInfo[_user];
        userRewardInfo.previousRew = uint256(userRewardInfo.previousRew).add(
            prevRew
        );

        user.totalDeposit += _amount;
        curTotalDept = curTotalDept.add(_amount);
        user.depositTime = block.timestamp;

        if (!isExist[user.referrer]) {
            referrals.push(user.referrer);
            isExist[user.referrer] = true;
        }

        orderInfos[_user].push(OrderInfo(_amount, block.timestamp));
        depositers.push(_user);

        refAddresses[user.referrer].push(_user); // add addresses against referrels

        billionReward();
        millionReward();
    }

    function _updateTeamNum(address _user) private {
        UserInfo storage user = userInfo[_user];
        address upline = user.referrer;
        for (uint256 i = 0; i < referDepth; i++) {
            if (upline != address(0)) {
                userInfo[upline].teamNum = userInfo[upline].teamNum.add(1);
                teamUsers[upline][i].push(_user);
                // _updateLevel(upline);
                if (upline == defaultRefer) break;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function billionReward() public {
        uint256 billPercents;
        uint256 singleRew;

        if (curTotalDept >= curBillionBalance) {
            billPercents = (curTotalDept.mul(curBillionPercents)).div(baseDivider);
            singleRew = billPercents.div(depositers.length);
            for (uint256 i; i < depositers.length; i++) {
                RewardInfo storage userRew = rewardInfo[depositers[i]];
                userRew.billRew = (userRew.billRew).add(singleRew);
            }

            curBillionBalance = curBillionBalance.add(contractBillionBalance);
            curBillionPercents = curBillionPercents.add(billionPercentage);

            if (curBillionPercents > 100) {
                curBillionPercents = billionPercentage;
            }
            extraBonus();
        }

    }

    function extraBonus() public {
        uint256 refPercents;
        uint256 singleRew;
        refPercents = (curTotalDept.mul(curCommission)).div(baseDivider);
        singleRew = refPercents.div(referrals.length);
        for (uint256 i; i < referrals.length; i++) {
            RewardInfo storage userRew = rewardInfo[referrals[i]];
            userRew.refIncome = (userRew.refIncome).add(singleRew);
        }
        curCommission = curCommission.add(referrelCommission);
        if (curCommission > 50) {
            curCommission = referrelCommission;
        }
    }

    //  community incentive
    function millionReward() public {
        uint256 millPercents;
        uint256 singleRew;

        if (curTotalDept >= curMillionBalance) {
            millPercents = (curTotalDept.mul(curMillionPercents)).div(baseDivider);
            singleRew = millPercents.div(depositers.length);
            for (uint256 i; i < depositers.length; i++) {
                RewardInfo storage userRew = rewardInfo[depositers[i]];
                userRew.millRew = (userRew.millRew).add(singleRew);
            }

            curMillionBalance = curMillionBalance.add(contractMillionBalance);
            curMillionPercents = curMillionPercents.add(millionPercentage);

            if (curMillionPercents > 50) {
                curMillionPercents = millionPercentage;
            }
        }
    }

    function userRewardTime(address _user) public view returns (uint256) {
        uint256 _time = ((block.timestamp).sub(userInfo[_user].depositTime)).div(timeStamp);
        return _time;
    }

    function userReward(address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 userDep = user.totalDeposit;
        uint256 _time = userRewardTime(_user);

        uint256 dayreward = (userDep.mul(dailyPercentage)).div(baseDivider);
        dayreward = ((dayreward).div(dayslots)).mul(_time);
        return dayreward.sub(withdrawedReward[_user]);
    }

    function bonusTime(address _user) public view returns (uint256) {
        uint256 _time = (block.timestamp.sub(userInfo[_user].lastClaim)).div(
            timeStamp
        );
        return _time;
    }

    function bonuPercentage(address _user) public view returns (uint256) {
        uint256 rewardPercent;
        uint256 dayReward;
        rewardPercent = ((userInfo[_user].totalDeposit).mul(minDailyBonus)).div(baseDivider);
        dayReward = rewardPercent.div(dayslots);
        return dayReward;
    }

    function bonusReward(address _user) public view returns (uint256) {
        uint256 dayReward;
        uint256 count = 0;
        uint256 totalTime;
        uint256 _time;
        uint256 reward;
        uint256 count1;

        if ((userInfo[_user].lastClaim) > 0) {
            if (
                (block.timestamp) >=
                ((userInfo[_user].lastClaim).add(10 minutes))  // dayDiff => 10 Minutes => 1 day
            ) {
                
                _time = bonusTime(_user);
                dayReward = bonuPercentage(_user);
                reward = dayReward.mul(_time);
                totalTime = _time;
                while (_time > finalTime) {
                    count++;
                    count1 = count.mul(dayslots);
                    _time = totalTime.sub(count1);
                    reward = _time.mul(dayReward);
                }
            }
        }

        return reward;
    }

    function userTotalReward(address _user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        RewardInfo storage userRew = rewardInfo[_user];
        // UserInfo storage user = userInfo[_user];
        uint256 userFinalRew;
        
        // uint256 userMaxRew = user.totalDeposit.mul(maxIncome);
        uint256 userMaxRew = 6e6; //  testing

        uint256 _bonusRew = bonusReward(_user);
        uint256 _reward = userReward(_user);
        userFinalRew = (userRew.millRew).add(userRew.billRew).add(userRew.refIncome);
        userFinalRew = userFinalRew.add(
            (_reward)
            .add(userRew.previousRew)
            .add(_bonusRew)
            .add(userRew.totalWithdrawl));

        if (userFinalRew >= userMaxRew) {
            userFinalRew = userMaxRew;
        }

        userFinalRew = userFinalRew.sub(userRew.totalWithdrawl);
        return (userFinalRew, _reward, _bonusRew);
    }

    function claimReward() public {
        billionReward();
        millionReward();

        RewardInfo storage userRew = rewardInfo[msg.sender];
        UserInfo storage user = userInfo[msg.sender];
        (, uint256 regRewards, uint256 _bonusRew) = userTotalReward(msg.sender);
        userRew.bonusRew = userRew.bonusRew.add(_bonusRew);
        withdrawedReward[msg.sender] = withdrawedReward[msg.sender].add(regRewards);
        user.lastClaim = block.timestamp;
    }

    function withdraw() public {
        RewardInfo storage userRew = rewardInfo[msg.sender];

        claimReward();
        (uint256 finalReward, , ) = userTotalReward(msg.sender);

        userRew.totalWithdrawl = (userRew.totalWithdrawl).add(finalReward);

        userRew.millRew = 0;
        userRew.billRew = 0;
        userRew.bonusRew = 0;

        payable(msg.sender).transfer(finalReward);
    }

    function updateLevelIncome(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < referDepth; i++) {
                if (upline != address(0)) {
                    uint256 amount = _amount.mul(levelsIncomePercents[i]).div(
                        baseDivider
                    );

                    if (amount > 0) {
                        rewardInfo[upline].levelIncome = rewardInfo[upline]
                            .levelIncome
                            .add(amount);
                    }
                    upline = userInfo[upline].referrer;
                } else break;
            }
        }
    }

    function changeBillionPercents(uint256 _percents) public onlyOwner {
        billionPercentage = _percents;
    }

    function changeMillionPercents(uint256 _percents) public onlyOwner {
        millionPercentage = _percents;
    }

    function changeReferrelPercents(uint256 _percents) public onlyOwner {
        referrelCommission = _percents;
    }
}