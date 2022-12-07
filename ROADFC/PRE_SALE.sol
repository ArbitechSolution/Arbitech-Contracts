// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
  
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    }

interface IPancakePair { 

    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1, uint32 _blockTimestampLast);

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
}
contract Ownable  {

    address public _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor()  {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract PreSale is Ownable{

    ///////////////////////   VARIABLES   ////////////////////////
    IERC20 public Token;
    IPancakePair public LPToken;

    uint256 public minimum = 0.1 ether;
    uint256 public maximum = 12 ether;
    uint256 public softCap = 1000 ether;
    uint256 public hardCap = 2000 ether;
    bool public Start;
    uint256 public startTime;
    uint256 public totalSold;
    using SafeMath for uint256;
    uint256 public price = 0.009 ether;
    address public wallet = 0x3CdffCaaee6cd6924716ff57765f06046a0bE9e3;

    //    0xe997A97DcA4710bBc53CCA0c0093A939Ca58bAfc

    /////////////////////////////////////////////////////////// 
    ///////////////////////   EVENTS   ////////////////////////

    event BUYER(address indexed from, uint256 indexed buyerTokens); 
    event TokenPrice(address indexed from, uint256 indexed tokenPrice);
    event BNBWallet(address indexed from, address indexed WalletAddress);
    event saleStatus(address indexed from, bool indexed Status);
    event ownerWithdraw(address indexed from, uint256 indexed BNB_Balance);

    /////////////////////////////////////////////////////////// 
    ///////////////////////   CONSTRUCTOR   ///////////////////

    constructor(IERC20 _Token, IPancakePair _LPToken ){
    LPToken = _LPToken ;
    Token = _Token;
    }

    //  user call this function to check its LP_Tokens
    function getVal() public view returns(uint256,uint256,uint256) {

    return LPToken.getReserves();

    }

    //  FUNCTION TO CALCULATE TOKENS PRICE AGAINST BNB
    function calculate_price(uint256 _BNB_amount) public view returns(uint256) {

        (uint256 reservev0,uint256 reservev1,)=getVal();
        uint256 per_BNB= (reservev1.mul(4865000000000000000).div(reservev0));
        uint256 perBUSD = _BNB_amount.mul(1 ether).div(price);
        uint TotalTOKEN = perBUSD.mul(per_BNB);
        return TotalTOKEN.div(1 ether);

    }

    //  BUY FUNCTION TO BUY TOKEN BY BNB

    function buy() public payable {

        require(Start == true ,"Pre Sale not started yet" );
        uint tokens = calculate_price(msg.value);
        require(msg.value >= minimum || msg.value <= maximum,"Insuffienct funds");
        Token.transfer(msg.sender,tokens);

        totalSold += tokens;
        emit BUYER(msg.sender, tokens);

    }

    //  FUNCTION to SET PRICE OF TOKEN

    function setVal(uint256 tokenValue) public onlyOwner
    {   
        price = tokenValue;
        emit TokenPrice(msg.sender, price);
    }

    //  FUNCTION TO CHANGE THE BNB WALLET 
    function changeWallet(address _recept) public onlyOwner
    {
        wallet = _recept;
        emit BNBWallet(msg.sender, wallet);
    }

    //  FUNCTION TO START THE PRESALE 
    function salestart() external onlyOwner
    {
        startTime = block.timestamp; 
        Start = true;
        emit saleStatus(msg.sender, Start);
    }

    //  FUNCTION TO END THE PRESALE 
    function endSale() external onlyOwner
    {
        Start = false;
        startTime = 0;
        emit saleStatus(msg.sender, Start);
    }

    
    //  FUNCTION TO WITHDRAW BNB

    function withdrawBNB() public onlyOwner
    {
        payable(wallet).transfer(address(this).balance);
        emit ownerWithdraw(msg.sender, (address(this).balance));
    }
}

    /*

    LP TOKEN ADDRESS:
    0x8B07fAf264C95e878bC87b351B412c79aC9F2759

    TOKEN ADDRESS:
    0x0C8538E68d598Ad5FC75b5F16A96A4187D47A802

    */