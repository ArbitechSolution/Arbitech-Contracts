// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burnbyContract(uint256 _amount) external;
    function withdrawStakingReward(address _address,uint256 _amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface GEN__1{
    function isStaked(address user_) external pure returns(bool a);
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed LockedTokenid);
    event Approval(address indexed owner, address indexed approved, uint256 indexed LockedTokenid);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 LockedTokenid) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 LockedTokenid) external;
    function transferFrom(address from,address to,uint256 LockedTokenid) external;
    function approve(address to, uint256 LockedTokenid) external;
    function getApproved(uint256 LockedTokenid) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 LockedTokenid,bytes calldata data) external;
}

contract Ownable {

    address public _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract SignVerify {

    /// signature methods.
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // bytes32 message = prefixed(keccak256(abi.encodePacked(msg.sender, amount, nonce, this)));
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

        return ecrecover(hash, v, r, s);
    }

    function toString(address account) public pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

contract OYAC_STAKING is Ownable, SignVerify{

    /////////////////////////       VARIABLES       ///////////////////////
    using SafeMath for uint256;
    IERC721 public NFT;
    IERC20 public Token;
    GEN__1 public GEN_1;
    address public DutuchAuction;
    uint256 Time= 5 seconds;
    uint256 LockingTime= 30 seconds;
    uint256 maxNoOfDays = 3;
    address public signer;
    ////////////////////             STRUCTURE         //////////////////
    struct LockeduserInfo 
    {
        uint256 totlaWithdrawn;
        uint256 totalStaked;
    }
    struct userInfo 
    {
        uint256 totlaWithdrawn;
        uint256 totalStaked;
    }
    /////////////////////////       MAPPING       ///////////////////////////
    mapping (address => LockeduserInfo ) public LockedUser;
    mapping (address => mapping(uint256 => uint256)) public LockedstakingTime;
    mapping (address => uint256[] ) public LockedTokenid;
    mapping (address => uint256) public LockedtotalStakedNft;
    mapping (uint256 => bool) public LockedalreadyAwarded;
    mapping (address => mapping(uint256 => uint256)) public lockeddepositTime;
    mapping (address => mapping(uint256 => uint256)) public stakingTime;
    mapping (address => userInfo ) public User;
    mapping (address => uint256[] ) public Tokenid;
    mapping (address => uint256) public totalStakedNft;
    mapping (uint256 => bool) public alreadyAwarded;
    mapping (address => mapping(uint256 => uint256)) public depositTime;
    mapping (bytes32 => bool) public usedHash;
    ////////////////////        CONSTRUCTOR & MODIFIER      ////////////////////
    constructor(IERC721 _NFTToken,IERC20 _token,GEN__1 Gen_1_Address)  
    {
        NFT =_NFTToken;
        Token=_token;
        GEN_1 = Gen_1_Address;
    }

    modifier onlyDutch()
    {
        require(msg.sender == address(NFT)  , "Caller is not from Ductch Auction");
        _;
    }

    /*
    * This function will be called in dutch mint function of OYAC contract.
    * After dutch minting token_ID will transferd in contract via from this function .
    * This function can be called only by the dutch auction contract users.
    */
    function lockedStaking(uint256 _Tokenid, address _user) external 
    onlyDutch 
    {

       LockedTokenid[_user].push(_Tokenid);
       LockedstakingTime[_user][_Tokenid]=block.timestamp;
       if(!LockedalreadyAwarded[_Tokenid]){
       lockeddepositTime[_user][_Tokenid]=block.timestamp;
        }       
       LockedUser[_user].totalStaked+=1;
       LockedtotalStakedNft[_user]+=1;
    }
    /*
    *** This function will return the total time after completion of locking period.
    */
    function lockedCalcTime(uint256 Tid,address user_) internal view returns(uint256)
    {
        uint256 noOfDays;
        if(LockedstakingTime[user_][Tid] > 0) {
        noOfDays = (block.timestamp.sub(LockedstakingTime[user_][Tid])).div(Time);
        if (noOfDays > maxNoOfDays) {
            noOfDays = maxNoOfDays;
            }
            else{
                noOfDays = 0;
            }
        }
        return noOfDays;
    }
    /*
    * Contract will decide reward for each NFT. (15 or 10) / day
    */
    function lockedperNFTReward(address addrs) internal view returns(uint256)
    {
        bool check = GEN_1.isStaked(addrs);
        uint256 rewardPerNFT;
        if(check == true) {
            rewardPerNFT = 15 ether;
            }
        else {
            rewardPerNFT = 10 ether;
            }
        return rewardPerNFT;
    }
    /*
    * This function will calculate the reward of each NFT.
    * Frist will check if user staked in GEN_1 then he will get 15 tokens/day otherwise he will get 10 tokens/day.
    */
    function lockedSingleReward(uint256 Tid, address user_) public view returns(uint256 single_reward)
    {
        uint256 noOfDays;
        uint256 rewardPerNFT = lockedperNFTReward(user_);
        
        for (uint256 i=0; i<LockedTokenid[user_].length; i++){
            if(
                LockedTokenid[user_][i] > 0) {
                noOfDays = lockedCalcTime(Tid,user_);
                if (noOfDays == maxNoOfDays){
                    single_reward = (rewardPerNFT).mul(noOfDays);
                    }
                else 
                {
                    noOfDays = 0;
                }
            }
        }
        return single_reward;
    }
    /*
    * This function will return total reward of the user against locked_staked NFTs.
    */
    function lockedtotalReward(address user_) public view returns(uint256)
    {
        uint256 ttlReward;
        for (uint256 i=0; i< LockedTokenid[user_].length; i++){
            ttlReward += lockedSingleReward(LockedTokenid[user_][i],user_);
            }
        return ttlReward;
    }
    /*
    * This function will return the NFTs that have completed the locking period.
    */
    function getIDS(address user_) public view returns(uint256[] memory) {
        uint256[] memory newids =  new uint256[] (LockeduserNFT_s(user_).length);
        for (uint256 i=0; i< LockeduserNFT_s(user_).length; i++){
            if(lockedCalcTime(LockedTokenid[user_][i], user_) > 0){
                newids[i] = LockedTokenid[user_][i];
            }
        }
        return newids;
    }
    /*
    * This function is used to withdraw and unstake at the same time.
    ***** (Only those NFTs that have completed their locking period can be unstaked.)
    **
    */
    function locked_Withdraw_Unstake()  public {
        
        uint256 totalReward = lockedtotalReward(msg.sender);
        require(totalReward > 0,"you don't have reward yet!");
        Token.withdrawStakingReward(msg.sender, totalReward);

        for(uint256 i=0; i < LockedTokenid[msg.sender].length;i++){
            uint256 _index=findlocked(LockedTokenid[msg.sender][i]);
            LockedalreadyAwarded[LockedTokenid[msg.sender][_index]]=true;
        }
        LockedUser[msg.sender].totlaWithdrawn +=  totalReward;
        unstakelocked(getIDS(msg.sender));
    }
    /*
    * This function will check if the ID is staked or not and return the number of locked FNTs
    */
    function findlocked(uint value) public view returns(uint) {
        uint i = 0;
        while (LockedTokenid[msg.sender][i] != value) {
            i++;
        }
        return i;
    }
    /*
    * This function will use to unstake the NFTs in 
    **** locked_Withdraw_Unstake()
    */
    function unstakelocked(uint256[] memory TokenIds) internal
    {
        address nftContract = msg.sender;
        for(uint256 i=0; i<TokenIds.length; i++){
            uint256 _index=findlocked(TokenIds[i]);
            require(lockedCalcTime(LockedTokenid[msg.sender][_index],msg.sender)==maxNoOfDays," TIME NOT REACHED YET ");
            require(LockedTokenid[msg.sender][_index] == TokenIds[i] ," NFT WITH THIS LOCKED_TOKEN_ID NOT FOUND ");
            NFT.transferFrom(address(this),address(nftContract),TokenIds[i]);
            delete LockedTokenid[msg.sender][_index];
            LockedTokenid[msg.sender][_index]=LockedTokenid[msg.sender][LockedTokenid[msg.sender].length-1];
            LockedstakingTime[msg.sender][TokenIds[i]]=0;
            LockedTokenid[msg.sender].pop();  
        }
        LockedUser[msg.sender].totalStaked -= TokenIds.length;
        LockedtotalStakedNft[msg.sender]>0?LockedtotalStakedNft[msg.sender] -= TokenIds.length:LockedtotalStakedNft[msg.sender]=0;
    } 
    /*
    * This function will return all the locked_staked NFTs.
    */
    function LockeduserNFT_s(address _staker)public view returns(uint256[] memory)
    {
       return LockedTokenid[_staker];
    }
    /*
    * This will return a bool statment if the user is Staked or not.
    */
    function isLockedStaked(address _stakeHolder)public view returns(bool)
    {
        if(LockedtotalStakedNft[_stakeHolder]>0){
            return true;
            }else{
            return false;
        }
    }


    ///////////////////      ONLY-OWNER FUNCTIONS     ////////////////////////
    /*
    * Owner's withdraw function to get token back from the contract.
    */
    function WithdrawToken()public onlyOwner 
    {
    require(Token.transfer(msg.sender,Token.balanceOf(address(this))),"Token transfer Error!");
    }

    function Add_Signer(address _signer) public onlyOwner
    {
        signer  = _signer;
    }

    /*
    - General function used to stake NFTs 
    -- Pre_Sale
    -- Public_Sale
    */
    function Stake(uint256[] memory tokenId) external 
    {  require(tokenId.length>0, " PLZ select ID " );
       for(uint256 i=0;i<tokenId.length;i++){
       require(NFT.ownerOf(tokenId[i]) == msg.sender,"NFT NOT FOUND");
       NFT.transferFrom(msg.sender,address(this),tokenId[i]);
       Tokenid[msg.sender].push(tokenId[i]);
       stakingTime[msg.sender][tokenId[i]]=block.timestamp;
       if(!alreadyAwarded[tokenId[i]]){
       depositTime[msg.sender][tokenId[i]]=block.timestamp;
       }
       }
       User[msg.sender].totalStaked+=tokenId.length;
       totalStakedNft[msg.sender]+=tokenId.length;
    }
    /*
    * This is general reward function in which user will get reward after staking NFT.
    -- Signature
    -- Nonce
    */
    function WithdrawReward(uint256 _reward,uint256 _nonce, bytes memory signature)  public 
    {
       require(_reward > 0,"you don't have reward yet!");
       require(Token.balanceOf(address(Token))>=_reward,"Contract Don't have enough tokens to give reward");
       bytes32 hash = keccak256(   
            abi.encodePacked(   
                toString(address(this)),   
                toString(msg.sender),
                _nonce
            )
        );
        require(!usedHash[hash], "Invalid Hash");   
        require(recoverSigner(hash, signature) == signer, "Signature Failed");
        usedHash[hash] = true;
        Token.withdrawStakingReward(msg.sender,_reward);
        User[msg.sender].totlaWithdrawn +=  _reward;
    }

    function find(uint value) internal  view returns(uint) {
        uint i = 0;
        while (Tokenid[msg.sender][i] != value) {
            i++;
        }
        return i;
    }
    /*
    * This is general unstake function in which user will unstake his NFTs.
    */
    function unstake(uint256[] memory _tokenId)  external 
    {
        require(_tokenId.length>0, " PLZs Select ID " );
        for(uint256 i=0;i<_tokenId.length;i++){
        uint256 _index=find(_tokenId[i]);
        require(Tokenid[msg.sender][_index] ==_tokenId[i] ,"NFT with this _tokenId not found");
        NFT.transferFrom(address(this),msg.sender,_tokenId[i]);
        delete Tokenid[msg.sender][_index];
        Tokenid[msg.sender][_index]=Tokenid[msg.sender][Tokenid[msg.sender].length-1];
        stakingTime[msg.sender][_tokenId[i]]=0;
        Tokenid[msg.sender].pop();
        }
        User[msg.sender].totalStaked-=_tokenId.length;
        totalStakedNft[msg.sender]>0?totalStakedNft[msg.sender]-=_tokenId.length:totalStakedNft[msg.sender]=0;
    }

    /*
    * This will return a bool statment if the user is stakeholder or not.
    */
    function isStaked(address _stakeHolder)public view returns(bool){
            if(totalStakedNft[_stakeHolder]>0){
            return true;
            }else{
            return false;
          }
    }
    function userStakedNFT(address _staker)public view returns(uint256[] memory) {
       return Tokenid[_staker];
    }


    // Signer_Address: 0x7D3A326D974496111Bdd18f0c1bC60b3Be865862
    // 0x0a2a308c5722B227B8eF8131Fc5b8448E6a8e665 gen_1

}