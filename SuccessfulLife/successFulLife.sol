// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SuccessLife {
    using SafeMath for uint256;

    uint256 public constant referrerLimit = 2;

    address public BUSD;

    address public owner;
    uint256 public currentId = 0;
    // uint256 public globalMatricID = 0;
    bool public lockStatus;
    uint256 public loopLimit = 64;
    uint256 public levelIncome = 50;
    uint256 public sponserIncome = 50;
    uint256 silverMatrixID = 1;
    uint256 goldMatrixID = 2;
    uint256 platinumMatrixID = 3;
    uint256 diamondMatrixID = 4;
    uint256 royalMatrixID = 5;

    // A struct to store information about each user in the matrix
    struct User {
        bool isExist;
        uint256 id;
        uint256 sponserID;
        uint256 currentLevel;
        uint256 totalEarningEth;
        address[] referral;
        uint256 directReferral;
    }

    // Mapping to store level price based on levels
    mapping(uint256 => uint256) public LEVEL_PRICE;

    // Mapping to store user information
    mapping(address => User) public users;
    mapping(uint256 => address) public userList;

    // Mapping to store the profit and loss
    mapping(address => mapping(uint256 => uint256)) public EarnedEth;
    mapping(address => mapping(uint256 => uint256)) public lostEth;

    // mapping to store joined date of user
    mapping(address => uint256) public joinedOn;

    //mapping for global matrix
    mapping(uint256 => mapping(uint256 => address[]))
        public globalMatrixReferrals;
    mapping(uint256 => uint256) public globalMatrixIncrement;
    mapping(address => mapping(uint256 => uint256)) public globalMatrixuserID;
    mapping(address => mapping(uint256 => uint256))
        public globalMatrixCurrentLevel;
    mapping(uint256 => mapping(uint256 => address))
        public globalmartixUseraddress;
    mapping(address => mapping(uint256 => uint256))
        public globalMatrixUserUpline;

    event Registered(
        address indexed UserAddress,
        address indexed ReferrerAddress,
        uint256 Time
    );
    event NewLevel(address indexed UserAddress, uint256 Level, uint256 Time);
    event Payment(
        address indexed UserAddress,
        uint256 Amount,
        uint256 UserId,
        address indexed ReferrerAddress,
        uint256 SponserID,
        uint256 Level,
        uint256 LevelPrice,
        uint256 Time
    );
    event LoopLimit(address Caller, uint256 NewLimit);

    constructor(address _owner, address _BUSD) {
        require(_owner != address(0x000), "Zero address");
        owner = _owner;
        BUSD = _BUSD;

        LEVEL_PRICE[1] = 10 * 10**18;
        LEVEL_PRICE[2] = 20 * 10**18;
        LEVEL_PRICE[3] = 30 * 10**18;
        LEVEL_PRICE[4] = 40 * 10**18;
        LEVEL_PRICE[5] = 50 * 10**18;
        LEVEL_PRICE[6] = 100 * 10**18;
        LEVEL_PRICE[7] = 200 * 10**18;

        User memory userStruct;
        currentId = currentId + (1);

        // Initialize owner as first upline
        userStruct = User({
            isExist: true,
            id: currentId,
            sponserID: 0,
            currentLevel: 7,
            totalEarningEth: 0,
            referral: new address[](0),
            directReferral: 0
        });

        users[_owner] = userStruct;
        userList[currentId] = _owner;

        // Silver matrix
        _updateSilverMatrix(_owner);

        // Gold matrix
        _updateGoldMatrix(_owner);

        // Platinum matrix
        _updatePlatinumMatrix(_owner);

        // Diamond matrix
        _updateDiamondMatrix(_owner);

        // Royal matrix
        _updateRoyalMatrix(_owner);
    }

    modifier isLocked() {
        require(lockStatus == false, "Contract locked");
        _;
    }

    modifier checkPayment(uint256 _level) {
        require((_level >= 1) && (_level <= 7), "Incorrect Level");
        require(
            IERC20(BUSD).balanceOf(msg.sender) >= LEVEL_PRICE[_level],
            "Insufficient balance"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    function _updateSilverMatrix(address _owner) internal {
        globalMatrixIncrement[silverMatrixID]++;

        globalMatrixuserID[_owner][silverMatrixID] = globalMatrixIncrement[
            silverMatrixID
        ];

        globalMatrixCurrentLevel[_owner][silverMatrixID] = 2;

        globalmartixUseraddress[silverMatrixID][
            globalMatrixIncrement[silverMatrixID]
        ] = _owner;

        globalMatrixUserUpline[_owner][silverMatrixID] = 1;
    }

    function _updateGoldMatrix(address _owner) internal {
        globalMatrixIncrement[goldMatrixID]++;

        globalMatrixuserID[_owner][goldMatrixID] = globalMatrixIncrement[
            goldMatrixID
        ];

        globalMatrixCurrentLevel[_owner][goldMatrixID] = 2;

        globalmartixUseraddress[goldMatrixID][
            globalMatrixIncrement[goldMatrixID]
        ] = _owner;

        globalMatrixUserUpline[_owner][goldMatrixID] = 1;
    }

    function _updatePlatinumMatrix(address _owner) internal {
        globalMatrixIncrement[platinumMatrixID]++;

        globalMatrixuserID[_owner][platinumMatrixID] = globalMatrixIncrement[
            platinumMatrixID
        ];

        globalMatrixCurrentLevel[_owner][platinumMatrixID] = 2;

        globalmartixUseraddress[platinumMatrixID][
            globalMatrixIncrement[platinumMatrixID]
        ] = _owner;

        globalMatrixUserUpline[_owner][platinumMatrixID] = 1;
    }

    function _updateDiamondMatrix(address _owner) internal {
        globalMatrixIncrement[diamondMatrixID]++;

        globalMatrixuserID[_owner][diamondMatrixID] = globalMatrixIncrement[
            diamondMatrixID
        ];

        globalMatrixCurrentLevel[_owner][diamondMatrixID] = 2;

        globalmartixUseraddress[diamondMatrixID][
            globalMatrixIncrement[diamondMatrixID]
        ] = _owner;

        globalMatrixUserUpline[_owner][diamondMatrixID] = 1;
    }

    function _updateRoyalMatrix(address _owner) internal {
        globalMatrixIncrement[royalMatrixID]++;

        globalMatrixuserID[_owner][royalMatrixID] = globalMatrixIncrement[
            royalMatrixID
        ];

        globalMatrixCurrentLevel[_owner][royalMatrixID] = 2;

        globalmartixUseraddress[royalMatrixID][
            globalMatrixIncrement[royalMatrixID]
        ] = _owner;

        globalMatrixUserUpline[_owner][royalMatrixID] = 1;
    }

    /**
     * @dev User registration
     */
    function registerUser(uint256 _sponserID)
        external
        isLocked
        checkPayment(1)
    {
        address currentUser = msg.sender;
        uint256 amount = LEVEL_PRICE[1];
        require(users[currentUser].isExist == false, "User exist");
        require(
            _sponserID > 0 && _sponserID <= currentId,
            "Incorrect referrer Id"
        );

        uint256 directRef = _sponserID;

        if (users[userList[_sponserID]].referral.length >= referrerLimit)
            _sponserID = users[findFreeReferrer(userList[_sponserID])].id;

        IERC20(BUSD).transferFrom(msg.sender, address(this), amount);

        User memory userStruct;
        currentId++;

        userStruct = User({
            isExist: true,
            id: currentId,
            sponserID: directRef, //Sponser
            currentLevel: 1,
            totalEarningEth: 0,
            referral: new address[](0),
            directReferral: _sponserID //upline
        });

        users[currentUser] = userStruct;
        userList[currentId] = currentUser;
        users[userList[_sponserID]].referral.push(currentUser);
        joinedOn[currentUser] = block.timestamp;

        payForLevelOne(1, userList[directRef], amount);

        emit Registered(currentUser, userList[_sponserID], block.timestamp);
    }

    /**
     * @dev To buy the next level by User
     */
    function enterNextLevel(uint256 _level)
        external
        isLocked
        checkPayment(_level)
    {
        address currentUser = msg.sender;
        require(users[currentUser].isExist, "User not exist");
        require(
            (_level > 1) &&
                (_level <= 7) &&
                (users[currentUser].currentLevel + 1 == _level),
            "Incorrect level"
        );
        uint256 amount = LEVEL_PRICE[_level];
        IERC20(BUSD).transferFrom(msg.sender, address(this), amount);
        users[currentUser].currentLevel = _level;
        payforSponser(_level, users[currentUser].sponserID, amount);
        payForLevel(_level, users[currentUser].directReferral, amount);

        emit NewLevel(currentUser, _level, block.timestamp);
    }

    function enterSilverMatrix(uint256 _level) external isLocked {
        require(
            users[msg.sender].currentLevel == 3,
            "Enter silver matrix after level 3"
        );

        require(
            (_level >= 1) &&
                (_level <= 2) &&
                (globalMatrixCurrentLevel[msg.sender][1] + 1 == _level),
            "Incorrect Level"
        );

        IERC20(BUSD).transferFrom(msg.sender, address(this), 30 * 1E18);

        globalMatrixIncrement[1]++;

        globalMatrixuserID[msg.sender][1] = globalMatrixIncrement[1];

        globalMatrixCurrentLevel[msg.sender][1] = _level;

        globalmartixUseraddress[1][globalMatrixIncrement[1]] = msg.sender;

        uint256 uplineID = 1;
        if (globalMatrixReferrals[uplineID][1].length >= 3)
            uplineID = globalMatrixuserID[
                findFreeReferrerForGlobalMatrix(
                    globalmartixUseraddress[goldMatrixID][1]
                )
            ][1];

        globalMatrixReferrals[uplineID][1].push(msg.sender);
        globalMatrixUserUpline[msg.sender][1] = uplineID;

        if (_level == 1) {
            IERC20(BUSD).transfer(
                globalmartixUseraddress[1][uplineID],
                30 * 1E18
            );
        }

        if (_level == 2) {
            uint256 firstUpline = globalMatrixUserUpline[msg.sender][1];
            uint256 secondUpline = findLevelUpdatedUser(1, firstUpline);
            /// --------------- have to check if second upline user is updated to level 2 ---------------------------///
            IERC20(BUSD).transfer(
                globalmartixUseraddress[1][secondUpline],
                30 * 1E18
            );
        }
    }

    function findLevelUpdatedUser(uint256 matrixID, uint256 firstUpline)
        internal
        view
        returns (uint256 secondUpline)
    {
        uint256 tempUpline = globalMatrixUserUpline[
            globalmartixUseraddress[matrixID][firstUpline]
        ][matrixID];
        for (uint256 i = 0; i <= loopLimit; i++) {
            if (
                globalMatrixCurrentLevel[
                    globalmartixUseraddress[matrixID][tempUpline]
                ][matrixID] == 2
            ) {
                secondUpline = tempUpline;
            } else {
                tempUpline = globalMatrixUserUpline[
                    globalmartixUseraddress[matrixID][tempUpline]
                ][matrixID];
            }
        }
    }

    function enterGoldMatrix(uint256 _level) external isLocked {
        require(
            users[msg.sender].currentLevel == 4,
            "Enter silver matrix after level 4"
        );

        require(
            (_level >= 1) &&
                (_level <= 2) &&
                (globalMatrixCurrentLevel[msg.sender][goldMatrixID] + 1 ==
                    _level),
            "Incorrect Level"
        );

        IERC20(BUSD).transferFrom(msg.sender, address(this), 30 * 1E18);

        globalMatrixIncrement[goldMatrixID]++;

        globalMatrixuserID[msg.sender][goldMatrixID] = globalMatrixIncrement[
            goldMatrixID
        ];

        globalMatrixCurrentLevel[msg.sender][goldMatrixID] = _level;

        globalmartixUseraddress[goldMatrixID][
            globalMatrixIncrement[goldMatrixID]
        ] = msg.sender;

        uint256 uplineID = 1;
        if (globalMatrixReferrals[uplineID][1].length >= 3)
            uplineID = globalMatrixuserID[
                findFreeReferrerForGlobalMatrix(
                    globalmartixUseraddress[goldMatrixID][1]
                )
            ][1];

        globalMatrixReferrals[uplineID][goldMatrixID].push(msg.sender);
        globalMatrixUserUpline[msg.sender][goldMatrixID] = uplineID;

        if (_level == 1) {
            IERC20(BUSD).transfer(
                globalmartixUseraddress[goldMatrixID][uplineID],
                30 * 1E18
            );
        }

        if (_level == 2) {
            uint256 firstUpline = globalMatrixUserUpline[msg.sender][
                goldMatrixID
            ];
            uint256 secondUpline = findLevelUpdatedUser(2, firstUpline);
            /// --------------- have to check if second upline user is updated to level 2 ---------------------------///
            IERC20(BUSD).transfer(
                globalmartixUseraddress[goldMatrixID][secondUpline],
                30 * 1E18
            );
        }
    }

    function enterPlatinumMatrix(uint256 _level) external isLocked {
        require(
            users[msg.sender].currentLevel == 5,
            "Enter silver matrix after level 5"
        );

        require(
            (_level >= 1) &&
                (_level <= 2) &&
                (globalMatrixCurrentLevel[msg.sender][platinumMatrixID] + 1 ==
                    _level),
            "Incorrect Level"
        );

        IERC20(BUSD).transferFrom(msg.sender, address(this), 30 * 1E18);

        globalMatrixIncrement[platinumMatrixID]++;

        globalMatrixuserID[msg.sender][
            platinumMatrixID
        ] = globalMatrixIncrement[platinumMatrixID];

        globalMatrixCurrentLevel[msg.sender][platinumMatrixID] = _level;

        globalmartixUseraddress[platinumMatrixID][
            globalMatrixIncrement[platinumMatrixID]
        ] = msg.sender;

        uint256 uplineID = 1;
        if (globalMatrixReferrals[uplineID][1].length >= 3)
            uplineID = globalMatrixuserID[
                findFreeReferrerForGlobalMatrix(
                    globalmartixUseraddress[platinumMatrixID][1]
                )
            ][1];

        globalMatrixReferrals[uplineID][platinumMatrixID].push(msg.sender);
        globalMatrixUserUpline[msg.sender][platinumMatrixID] = uplineID;

        if (_level == 1) {
            IERC20(BUSD).transfer(
                globalmartixUseraddress[platinumMatrixID][uplineID],
                30 * 1E18
            );
        }

        if (_level == 2) {
            uint256 firstUpline = globalMatrixUserUpline[msg.sender][
                platinumMatrixID
            ];
            uint256 secondUpline = findLevelUpdatedUser(3, firstUpline);
            /// --------------- have to check if second upline user is updated to level 2 ---------------------------///
            IERC20(BUSD).transfer(
                globalmartixUseraddress[platinumMatrixID][secondUpline],
                30 * 1E18
            );
        }
    }

    function enterDiamondMatrix(uint256 _level) external isLocked {
        require(
            users[msg.sender].currentLevel == 6,
            "Enter silver matrix after level 6"
        );

        require(
            (_level >= 1) &&
                (_level <= 2) &&
                (globalMatrixCurrentLevel[msg.sender][diamondMatrixID] + 1 ==
                    _level),
            "Incorrect Level"
        );

        IERC20(BUSD).transferFrom(msg.sender, address(this), 30 * 1E18);

        globalMatrixIncrement[diamondMatrixID]++;

        globalMatrixuserID[msg.sender][diamondMatrixID] = globalMatrixIncrement[
            diamondMatrixID
        ];

        globalMatrixCurrentLevel[msg.sender][diamondMatrixID] = _level;

        globalmartixUseraddress[diamondMatrixID][
            globalMatrixIncrement[diamondMatrixID]
        ] = msg.sender;

        uint256 uplineID = 1;
        if (globalMatrixReferrals[uplineID][1].length >= 3)
            uplineID = globalMatrixuserID[
                findFreeReferrerForGlobalMatrix(
                    globalmartixUseraddress[diamondMatrixID][1]
                )
            ][1];

        globalMatrixReferrals[uplineID][diamondMatrixID].push(msg.sender);
        globalMatrixUserUpline[msg.sender][diamondMatrixID] = uplineID;

        if (_level == 1) {
            IERC20(BUSD).transfer(
                globalmartixUseraddress[diamondMatrixID][uplineID],
                30 * 1E18
            );
        }

        if (_level == 2) {
            uint256 firstUpline = globalMatrixUserUpline[msg.sender][
                diamondMatrixID
            ];
            uint256 secondUpline = findLevelUpdatedUser(4, firstUpline);
            /// --------------- have to check if second upline user is updated to level 2 ---------------------------///
            IERC20(BUSD).transfer(
                globalmartixUseraddress[diamondMatrixID][secondUpline],
                30 * 1E18
            );
        }
    }

    function enterRoyalMatrix(uint256 _level) external isLocked {
        require(
            users[msg.sender].currentLevel == 7,
            "Enter silver matrix after level 7"
        );

        require(
            (_level >= 1) &&
                (_level <= 2) &&
                (globalMatrixCurrentLevel[msg.sender][royalMatrixID] + 1 ==
                    _level),
            "Incorrect Level"
        );

        IERC20(BUSD).transferFrom(msg.sender, address(this), 30 * 1E18);

        globalMatrixIncrement[royalMatrixID]++;

        globalMatrixuserID[msg.sender][royalMatrixID] = globalMatrixIncrement[
            royalMatrixID
        ];

        globalMatrixCurrentLevel[msg.sender][royalMatrixID] = _level;

        globalmartixUseraddress[royalMatrixID][
            globalMatrixIncrement[royalMatrixID]
        ] = msg.sender;

        uint256 uplineID = 1;
        if (globalMatrixReferrals[uplineID][1].length >= 3)
            uplineID = globalMatrixuserID[
                findFreeReferrerForGlobalMatrix(
                    globalmartixUseraddress[royalMatrixID][1]
                )
            ][1];

        globalMatrixReferrals[uplineID][royalMatrixID].push(msg.sender);
        globalMatrixUserUpline[msg.sender][royalMatrixID] = uplineID;

        if (_level == 1) {
            IERC20(BUSD).transfer(
                globalmartixUseraddress[royalMatrixID][uplineID],
                30 * 1E18
            );
        }

        if (_level == 2) {
            uint256 firstUpline = globalMatrixUserUpline[msg.sender][
                royalMatrixID
            ];
            uint256 secondUpline = findLevelUpdatedUser(5, firstUpline);
            /// --------------- have to check if second upline user is updated to level 2 ---------------------------///
            IERC20(BUSD).transfer(
                globalmartixUseraddress[royalMatrixID][secondUpline],
                30 * 1E18
            );
        }
    }

    // check for level upgrade
    function payforSponser(
        uint256 _level,
        uint256 _sponserID,
        uint256 _levelPrice
    ) internal {
        uint256 _sponserShare = (_levelPrice * sponserIncome) / 100;
        uint256 _currentlevelSponser = _sponserID;
        for (uint256 i = 0; i <= loopLimit; i++) {
            if (users[userList[_currentlevelSponser]].currentLevel == _level) {
                _sponserID = _currentlevelSponser;
                break;
            } else {
                _currentlevelSponser = users[userList[_currentlevelSponser]]
                    .sponserID;
            }
        }
        sendPayment(userList[_sponserID], _sponserShare, _level, _levelPrice);
    }

    function payForLevel(
        uint256 _level,
        uint256 _directUplineID,
        uint256 _levelPrice
    ) internal {
        uint256 levelProfitUserID;
        if (_level == 2) {
            //second level upline
            // console.log("in payfor level %s", users[userList[_directUplineID]].directReferral);
            levelProfitUserID = findLevelUser(
                _level,
                users[userList[_directUplineID]].directReferral
            );
        } else if (_level == 3) {
            // third level upline
            uint256 secondID = users[userList[_directUplineID]].directReferral;
            // levelProfitUserID = users[userList[secondID]].directReferral;
            levelProfitUserID = findLevelUser(
                _level,
                users[userList[secondID]].directReferral
            );
        } else if (_level == 4) {
            // fourth level upline
            uint256 secondID = users[userList[_directUplineID]].directReferral;
            uint256 thirdID = users[userList[secondID]].directReferral;
            // levelProfitUserID = users[userList[thirdID]].directReferral;
            levelProfitUserID = findLevelUser(
                _level,
                users[userList[thirdID]].directReferral
            );
        } else if (_level == 5) {
            // fifth level upline
            uint256 secondID = users[userList[_directUplineID]].directReferral;
            uint256 thirdID = users[userList[secondID]].directReferral;
            uint256 fourthID = users[userList[thirdID]].directReferral;
            // levelProfitUserID = users[userList[fourthID]].directReferral;
            levelProfitUserID = findLevelUser(
                _level,
                users[userList[fourthID]].directReferral
            );
        } else if (_level == 6) {
            // sixth level upline
            uint256 secondID = users[userList[_directUplineID]].directReferral;
            uint256 thirdID = users[userList[secondID]].directReferral;
            uint256 fourthID = users[userList[thirdID]].directReferral;
            uint256 fifthID = users[userList[fourthID]].directReferral;
            // levelProfitUserID = users[userList[fifthID]].directReferral;
            levelProfitUserID = findLevelUser(
                _level,
                users[userList[fifthID]].directReferral
            );
        } else if (_level == 7) {
            // seventh level upline
            uint256 secondID = users[userList[_directUplineID]].directReferral;
            uint256 thirdID = users[userList[secondID]].directReferral;
            uint256 fourthID = users[userList[thirdID]].directReferral;
            uint256 fifthID = users[userList[fourthID]].directReferral;
            uint256 sixthID = users[userList[fifthID]].directReferral;
            // levelProfitUserID = users[userList[sixthID]].directReferral;
            levelProfitUserID = findLevelUser(
                _level,
                users[userList[sixthID]].directReferral
            );
        }
        uint256 levelShare = (_levelPrice * levelIncome) / 100;
        if (levelProfitUserID == 0) {
            levelProfitUserID = 1;
        }
        sendPayment(
            userList[levelProfitUserID],
            levelShare,
            _level,
            _levelPrice
        );
    }

    function findLevelUser(uint256 _level, uint256 _directReferral)
        public //internal
        view
        returns (uint256 levelProfitUserID)
    {
        uint256 templevel2 = _directReferral;
        for (uint256 i = 0; i <= loopLimit; i++) {
            // setting max loop to 60  // TBD
            if (users[userList[templevel2]].currentLevel >= _level) {
                levelProfitUserID = templevel2;
                break;
            } else {
                templevel2 = users[userList[templevel2]].directReferral;
            }
        }
    }

    /**
     * @dev Internal function for payment
     */
    function payForLevelOne(
        uint256 _level,
        address _directRef, //upline
        uint256 _levelPrice
    ) internal {
        // send full payment to direct upline
        sendPayment(_directRef, _levelPrice, _level, _levelPrice);
    }

    function sendPayment(
        address _receiver,
        uint256 _amount,
        uint256 _level,
        uint256 levelPrice
    ) 
    private 
    {
        // require((address(uint160(_receiver)).send(_amount)), "Transfer failed");
        IERC20(BUSD).transfer(_receiver, _amount);
        users[_receiver].totalEarningEth = users[_receiver].totalEarningEth.add(
            _amount
        );
        EarnedEth[_receiver][_level] = EarnedEth[_receiver][_level].add(
            _amount
        );
        emit Payment(
            msg.sender,
            _amount,
            users[msg.sender].id,
            _receiver,
            users[_receiver].id,
            _level,
            levelPrice,
            block.timestamp
        );
    }

    /**
     * @dev Contract balance withdraw
     */
    function failSafe(address payable _toUser, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        require(_toUser != address(0), "Zero address");
        require(
            IERC20(BUSD).balanceOf(address(this)) >= _amount,
            "Insufficient balance"
        );
        IERC20(BUSD).transfer(_toUser, _amount);
        return true;
    }

    /**
     * @dev Update contract status
     */
    function contractLock(bool _lockStatus) public onlyOwner returns (bool) {
        lockStatus = _lockStatus;
        return true;
    }

    /**
     * @dev Update the loop limit
     */
    function updateLoopLimit(uint256 _newLimit) public returns (bool) {
        loopLimit = _newLimit;
        emit LoopLimit(msg.sender, _newLimit);
        return true;
    }

    /**
     * @dev View free Referrer Address
     */
    function findFreeReferrer(address _userAddress)
        public
        view
        returns (address)
    {
        if (users[_userAddress].referral.length < referrerLimit)
            return _userAddress;

        address[] memory referrals = new address[](254);
        referrals[0] = users[_userAddress].referral[0];
        referrals[1] = users[_userAddress].referral[1];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint256 i = 0; i < 254; i++) {
            if (users[referrals[i]].referral.length == referrerLimit) {
                if (i < 126) {
                    referrals[(i + 1) * 2] = users[referrals[i]].referral[0];
                    referrals[(i + 1) * 2 + 1] = users[referrals[i]].referral[
                        1
                    ];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, "No Free Referrer");
        return freeReferrer;
    }

    /**
     * @dev View free Referrer Address for Global Matrix
     */
    function findFreeReferrerForGlobalMatrix(address _userAddress)
        public
        view
        returns (address)
    {
        if (users[_userAddress].referral.length < 3) return _userAddress;

        address[] memory referrals = new address[](254);
        referrals[0] = users[_userAddress].referral[0];
        referrals[1] = users[_userAddress].referral[1];
        referrals[2] = users[_userAddress].referral[2];

        address freeReferrer;
        bool noFreeReferrer = true;

        for (uint256 i = 0; i < 254; i++) {
            if (users[referrals[i]].referral.length == 3) {
                if (i < 126) {
                    referrals[(i + 1) * 2] = users[referrals[i]].referral[0];
                    referrals[(i + 1) * 2 + 1] = users[referrals[i]].referral[
                        1
                    ];
                    referrals[(i + 1) * 2 + 2] = users[referrals[i]].referral[
                        2
                    ];
                }
            } else {
                noFreeReferrer = false;
                freeReferrer = referrals[i];
                break;
            }
        }
        require(!noFreeReferrer, "No Free Referrer");
        return freeReferrer;
    }

    /**
     * @dev Total earned ETH
     */
    function getTotalEarnedEther() public view returns (uint256) {
        uint256 totalEth;
        for (uint256 i = 1; i <= currentId; i++) {
            totalEth = totalEth.add(users[userList[i]].totalEarningEth);
        }
        return totalEth;
    }

    /**
     * @dev View referrals
     */
    function viewUserReferrals(address _userAddress)
        external
        view
        returns (address[] memory)
    {
        return users[_userAddress].referral;
    }

    // fallback
    receive() external payable {
        revert("Invalid Transaction");
    }
}
