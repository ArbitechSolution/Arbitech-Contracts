// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.17;

  /*
    * minimum deposit 50E18
    * only activate function
    * owner can withdraw Token {token name}
  */


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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
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

contract ActivationContract is Ownable {

    using SafeMath for uint256;
    IERC20 public Token;

    uint256 private constant minDeposit = 50e18;
    constructor()
    {   Token = IERC20(0x09B34e72481905A74E463e942Ee8De0Fe52B0203);     }

    mapping (address => uint256) public totalActivatedPackage;
    mapping (address => uint256) public recentActivatedPackage;

    function register(address address_) public pure returns(address)
    {   return address_;    }

    function Activate(uint256 amount_)
    public
    {
        require(msg.sender == tx.origin,"External Err");
        require(amount_.mod(minDeposit) == 0 && amount_ >= minDeposit, "mod err");
        require(Token.allowance(msg.sender,address(this)) >= amount_,"Approve Token First");
        Token.transferFrom(msg.sender,address(this),amount_);
        totalActivatedPackage[msg.sender] = totalActivatedPackage[msg.sender].add(amount_);
        recentActivatedPackage[msg.sender] = amount_;
    }

    function withdraw(address tokenAddress, uint256 tokenAmount)
    public
    onlyOwner
    {       IERC20(tokenAddress).transfer(msg.sender,tokenAmount);      }

    function emergencyWithdraw()
    public
    onlyOwner
    {       Token.transfer(msg.sender,Token.balanceOf(address(this)));     }

}