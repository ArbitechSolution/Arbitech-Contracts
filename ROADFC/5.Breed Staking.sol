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
    function check_type(uint256 _id) external pure returns(uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface IERC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
    
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

contract BREED_Staking is Ownable {

    ////////////    Variables   ////////////

    using SafeMath for uint256;
    IERC721 public Breed;
    IERC20 public Token;
    
    uint256 time= 30 seconds;
    uint256 public publicMining;
    uint256 public publicNFTs;

    ////////////    Structure   ////////////

    struct userInfo 
    {
        uint256 totlaWithdrawn;
        uint256 myNFT;
        uint256 myMining;
    }

    ////////////    Mapping   ////////////

    mapping(address => userInfo ) public User;
    mapping(address => mapping(uint256 => uint256)) public stakingTime;
    mapping(address => uint256[] ) public Tokenid;
    mapping(address => uint256) public totalStakedNft;
    mapping(uint256 => bool) public alreadyAwarded;
    mapping(address => mapping(uint256=>uint256)) public depositTime;
    mapping(address => mapping(uint256 => uint256)) public rewardedAmount;

   /////////////    Events   /////////////

    event Staked(address indexed from, uint256 tokenIds);
    event Withdrawl(address indexed from, uint256 indexed tokenRew);
    event unstakeSingle(address indexed from, uint256 indexed TOKEN_ID);
    event unStakeAll(address indexed from, uint256 indexed Total_Ids);
    event OwnerWithDraw(address indexed from, uint256 indexed tokens);



    /////////////    Hash Powers   /////////////
    uint256 a = 50;
    uint256 b = 100;
    uint256 c = 250;
    uint256 d = 500;
    uint256 e = 1000;
    uint256 f = 5000;

    ////////////    Constructor   ////////////

    constructor(IERC721 _BREED,IERC20 _token)  
    {
        Breed   = _BREED;
        Token = _token;
    }

    ///////////////////     STAKE     /////////////////

    /*
    ==> Stake NFT'S to get reward in ROAD Coin
    =>  NFTs should be existed in Breed to Stake
    =>  set Staking time of tokenId
    =>  then addPower
    ==> stores the length of array in struct, publicNFT(variable)
    */ 

    function Stake(uint256[] memory tokenId) external
    {
       for(uint256 i=0;i<tokenId.length;i++){
        require(Breed.ownerOf(tokenId[i]) == msg.sender,"Nft Not Found");
        Breed.transferFrom(msg.sender,address(this),tokenId[i]);
        Tokenid[msg.sender].push(tokenId[i]);
        stakingTime[msg.sender][tokenId[i]]=block.timestamp;
        addPower(tokenId[i]);
        if(!alreadyAwarded[tokenId[i]]){
        depositTime[msg.sender][tokenId[i]]=block.timestamp;
        }

        }
        publicNFTs += tokenId.length;
       User[msg.sender].myNFT += tokenId.length;
       totalStakedNft[msg.sender]+=tokenId.length;
       emit Staked(msg.sender, tokenId.length);

    }

    
    /*
    ==> This function will set the hash_power of TokenId according to its type
    ==> This function calls internally
    */
    
    function addPower(uint256 _TokenId) internal
    {
        if(Token.check_type(_TokenId) == 1){
            publicMining +=a;
            User[msg.sender].myMining += a;
        }
        if(Token.check_type(_TokenId) == 2){
            publicMining +=b;
            User[msg.sender].myMining += b; 
        }
        else if(Token.check_type(_TokenId) == 3){
            publicMining +=c;
            User[msg.sender].myMining += c; 
        }
        else if(Token.check_type(_TokenId) == 4){
            publicMining +=d;
            User[msg.sender].myMining += d; 
        }
        else if(Token.check_type(_TokenId) == 5){
            publicMining +=e;
            User[msg.sender].myMining += e; 
        }
        else if(Token.check_type(_TokenId) == 6){
            publicMining +=f;
            User[msg.sender].myMining += f; 
        }
    }  

    // User can check the Type of TokenId
    function getlist(uint256 tokeniddd) public view returns(uint256)
    {
        return Token.check_type(tokeniddd);
    }


    /*
    ==> User will pass the address and TokenId
    =>  contract will check the tokenId type then calculate its reward.
    ==> reward is calculated according to 1 day time
    */
   
    function rewardOfUser(address Add, uint256 Tid) public view returns(uint256)
    {
        uint256 RewardToken;
        for(uint256 i = 0 ; i < Tokenid[Add].length ; i++){
           
            if(Token.check_type(Tid) == 1 && Tokenid[Add][i] == Tid)
            {
             RewardToken += (((block.timestamp - (stakingTime[Add][Tokenid[Add][i]])).div(time)))*50 ether;     
            }
            if(Token.check_type(Tid) == 2 && Tokenid[Add][i] == Tid)
            {
             RewardToken += (((block.timestamp - (stakingTime[Add][Tokenid[Add][i]])).div(time)))*100 ether;     
            }
            if(Token.check_type(Tid) == 3 && Tokenid[Add][i] == Tid)
            {
             RewardToken += (((block.timestamp - (stakingTime[Add][Tokenid[Add][i]])).div(time)))*250 ether;     
            }
            if(Token.check_type(Tid) == 4 && Tokenid[Add][i] == Tid)
            {
             RewardToken += (((block.timestamp - (stakingTime[Add][Tokenid[Add][i]])).div(time)))*500 ether;     
            }
            if(Token.check_type(Tid) == 5 && Tokenid[Add][i] == Tid)
            {
             RewardToken += (((block.timestamp - (stakingTime[Add][Tokenid[Add][i]])).div(time)))*1000 ether;     
            }
            if(Token.check_type(Tid) == 6 && Tokenid[Add][i] == Tid)
            {
             RewardToken += (((block.timestamp - (stakingTime[Add][Tokenid[Add][i]])).div(time)))*5000 ether;     
            }
        }
    return RewardToken - rewardedAmount[Add][Tid] ;
    }


    //  User passes the address to check its Staked ids 
    
    function userStakedNFT(address _staker)public view returns(uint256[] memory)
    {
       return Tokenid[_staker];
    }



    // User passes the address to check its total reward

    function totalReward(address addrs) public view returns(uint256)
    {
        uint256 reward;
        uint256[] memory arrNFT = userStakedNFT(addrs);
        for(uint256 i; i< arrNFT.length; i++){
            reward += rewardOfUser(addrs, Tokenid[addrs][i]);
        }
        return reward;
    }

    //////////////////   Withdraw-Reward   ///////////////////

    /*
    ==> User pass the TokenId and get its Reward
    =>  get Reward will then transfer to user
    =>  after transferring the reward, staking time will be zero 
    =>  and the calculated reward will stored in "User" Mapping
    => Then given Id will set to true in Mapping(alreadyAwarded)
    ==> user can only draw the single Id reward
    */

    function WithdrawReward(uint256 Tid)  internal
    {
       uint256 reward = rewardOfUser(msg.sender, Tid);
       require(reward > 0,"you don't have reward yet!");
       Token.transfer(msg.sender,reward); 
       rewardedAmount[msg.sender][Tid]=reward;

       User[msg.sender].totlaWithdrawn +=  reward;

       for(uint256 i = 0 ; i < Tokenid[msg.sender].length ; i++){
        alreadyAwarded[Tokenid[msg.sender][i]]=true;
       }
    }

 
    //////////////////   withDraw all at once  //////////////////

    /*
    ==> In this function, user can only withdraw the total reward all at once 
    ==> And the  time will reset to current time
    */ 

    function WithdrawRewardAll()  public
    {
       uint256 reward = totalReward(msg.sender);
       require(reward > 0,"you don't have reward yet!");
       
       Token.transfer(msg.sender,reward);
       User[msg.sender].totlaWithdrawn +=  reward;

       for(uint256 i = 0 ; i < Tokenid[msg.sender].length ; i++){
        alreadyAwarded[Tokenid[msg.sender][i]]=true;
        uint256 _index=find(Tokenid[msg.sender][i]);
        rewardedAmount[msg.sender][Tokenid[msg.sender][_index]]+=rewardOfUser(msg.sender,Tokenid[msg.sender][_index]);
       }
       emit Withdrawl(msg.sender, reward);
    }

    ////////////    Get index by Value   ////////////

    /*
    ==> this function will return the tokenId index from array stiored in the mapping against address
    ==> this function will call internally from unstake function
    */

    function find(uint value) internal  view returns(uint)
    {
        uint i = 0;
        while (Tokenid[msg.sender][i] != value) {
            i++;
        }
        return i;
    }


    ////////////    User have to pass tokenid to unstake   ////////////

    /*
    ==> User pass the tokenId to unstake 
    =>  WithdrawReward function will call from it and reward will transfer to the caller
    => Find the token_Id index in th array and
    =>  then pop the Id
    */


    function unstake(uint256 _tokenId)  external 
    {
        WithdrawReward(_tokenId);
        removePower(_tokenId);
        if(rewardOfUser(msg.sender, _tokenId)>0)alreadyAwarded[_tokenId]=true;
        uint256 _index=find(_tokenId);
        require(Tokenid[msg.sender][_index] ==_tokenId ,"NFT with this _tokenId not found");
        Breed.transferFrom(address(this),msg.sender,_tokenId);
        delete Tokenid[msg.sender][_index];
        Tokenid[msg.sender][_index]=Tokenid[msg.sender][Tokenid[msg.sender].length-1];
        stakingTime[msg.sender][_tokenId]=0;
        Tokenid[msg.sender].pop();
        publicNFTs -= 1;
        User[msg.sender].myNFT -= 1;
        totalStakedNft[msg.sender] > 0 ? totalStakedNft[msg.sender] -= 1 : totalStakedNft[msg.sender]=0;
        emit unstakeSingle(msg.sender, _tokenId);
    }

    //////////////////      REMOVE POWER     ///////////////////

    /*
    ==> this function will call internally from unstake function to 
        remove its power by checking its type in Breed Function
    */

    function removePower(uint256 _TokenId) internal
    {
        if(Token.check_type(_TokenId) == 1){
            publicMining -=a;
            User[msg.sender].myMining -= a; 
        }
        if(Token.check_type(_TokenId) == 2){
            publicMining -=b;
            User[msg.sender].myMining -= b; 
        }
        else if(Token.check_type(_TokenId) == 3){
            publicMining -=c;
            User[msg.sender].myMining -= c; 
        }
        else if(Token.check_type(_TokenId) == 4){
            publicMining -=d;
            User[msg.sender].myMining -= d; 
        }
        else if(Token.check_type(_TokenId) == 5){
            publicMining -=e;
            User[msg.sender].myMining -= e; 
        }
        else if(Token.check_type(_TokenId) == 6){
            publicMining -=f;
            User[msg.sender].myMining -= f; 
        }
    }

    //////////////////////   unstakeAll    ///////////////////

    /*
    ==> User passes the array of tokenIds
    =>  WithdrawAll function will call and the reward will transfer to the function caller
    =>  then user will remove the powers of all tokenIds
    =>  after removing the power, tokenIds will be transfered to caller address
    =>  staking time will set to zero
    =>  and Ids will remove from user's stakes
    */
    
    function unstakeAll(uint256[] memory _tokenId)  external 
    {
        WithdrawRewardAll();
        for(uint256 i=0;i<_tokenId.length;i++){
        removePower(_tokenId[i]);
        if(rewardOfUser(msg.sender, _tokenId[i])>0)alreadyAwarded[_tokenId[i]]=true;
        uint256 _index=find(_tokenId[i]);
        require(Tokenid[msg.sender][_index] == _tokenId[i] ,"NFT with this _tokenId not found");
        Breed.transferFrom(address(this),msg.sender,_tokenId[i]);
        delete Tokenid[msg.sender][_index];
        Tokenid[msg.sender][_index]=Tokenid[msg.sender][Tokenid[msg.sender].length-1];
        stakingTime[msg.sender][_tokenId[i]]=0;
        Tokenid[msg.sender].pop();
        }

        publicNFTs -= _tokenId.length;
        User[msg.sender].myNFT -= _tokenId.length;
        totalStakedNft[msg.sender]>0?totalStakedNft[msg.sender]-=_tokenId.length:totalStakedNft[msg.sender]=0;
        emit unStakeAll(msg.sender, _tokenId.length);
    }  

    //////////////////////   isStaked   ////////////////////////

    //  User Passes the address to check if the User staked any token_amount or not 

    function isStaked(address _stakeHolder)public view returns(bool)
    {
        if(totalStakedNft[_stakeHolder]>0){
            return true;
            }else{
            return false;
        }
    }

    ////////////    Withdraw Token   ////////////

    // onlyOwner can call this function and token will be transfered to owner address

    function WithdrawToken()public onlyOwner
    {
        require(Token.transfer(msg.sender,Token.balanceOf(address(this))),"Token transfer Error!");
        emit OwnerWithDraw(msg.sender, Token.balanceOf(address(this)));
    } 

}


/*
    BREED 
    0x41d4B49743b99324160d28A586A9e0B76798c8aF

    TOKEN
    0x52db35aC6393aEc5B8572cfde96B38DA4f7D149c
*/

