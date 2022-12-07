// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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

contract Ownable{

    event OwnershipTransferred(address previousOwner, address newOwner);
    
    address ownerAddress;
    
    constructor () {
        ownerAddress = msg.sender;
    }
    
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    /**
    * @dev Tells the address of the owner
    * @return the address of the owner
    */
    function owner() public view returns (address) {
        return ownerAddress;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner the address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    /**
    * @dev Sets a new owner address
    */
    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        ownerAddress = newOwner;
    }
}

interface IERC721{
    function getNFtHolders() external view returns(address[]memory);
}

contract BCBtoKlayReward is Ownable{
    using SafeMath for uint256;
    IERC721 public NFT;

    constructor (IERC721 _NFT) {
        NFT = _NFT;
    }
    event klayReward(address from, address to, uint256 value);

    struct userInfo
    {
        uint256 klayReward;
        uint256 lastRewardTime;
    }
    mapping (address=>userInfo) public userRewardInfo;

    /**
    * Owner will send rewards to NFT Holders
    * Function will be called by API
    */
    function sendToAll(address[] memory NFTHolders) public onlyOwner {
        uint256 contracBalance = address(this).balance;
        uint256 forEach = contracBalance.div(NFTHolders.length);
        for(uint256 i=0;i<NFTHolders.length;i++){
            userRewardInfo[NFTHolders[i]].klayReward+=forEach;
            userRewardInfo[NFTHolders[i]].lastRewardTime+=block.timestamp;
            payable(NFTHolders[i]).transfer(forEach);
            emit klayReward(address(this),NFTHolders[i],forEach);
        }
    }

    function getAllNftHolders() public view returns(address[] memory) {
        return NFT.getNFtHolders();
    }

    /**
    * function to get balance of this contract
    */
    function getContractBalance() public view returns(uint256){
        return address(this).balance;
    }
    /**
    * function to get balance of user
    */
    function getUserBalance(address _user) public view returns(uint256) {
        return _user.balance;
    }
    /**
    * function to Withdraw Klay from this contract
    * only callable from owner()'s address
    */
    function withdrawKlay() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }

    function getUserInfo(address _user) public view returns(uint256){
        return (userRewardInfo[_user].klayReward);
    }
}
