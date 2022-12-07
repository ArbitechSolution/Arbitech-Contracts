// SPDX-License-Identifier:MIT
pragma solidity ^0.8.15;

library SafeMath {
 
    function Add(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function Sub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function Mul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function Div(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function Mod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a,uint256 b,string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface IBEP20{

    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address receiver, uint256 tokenAmount) external  returns(bool);
    function transferFrom( address tokenOwner, address recipient, uint256 tokenAmount) external returns(bool);
    function allownce( address tokenOwner, address spender) external returns(uint256);
    function approve (address spender, uint256 tokenAmount ) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 tokenAmount);
    event approval( address indexed tokenOwner, address indexed spender, uint256 tokenAmount);
}

contract ATS is IBEP20{
    using SafeMath for uint256;

    string public constant tokenName = "Arbitech Solutions";
    string public constant tokenSymbol = "ATS";
    uint8 public  constant tokenDecimal  = 18;
    uint256 internal totalSupply_;
    address public owner;
    uint256 public rewardReserved ; //7000000000 ==>  70%
    uint256 public teamReserved ; // 1000000000 ==> 10%
    uint256 public marketingReserved; //1500000000 ==> 15%
    uint256 public charityReserved; //500000000 ==> 5%
    //uint256 public rewardBurningPercentage ; // 3% of reward


mapping(address => uint256) public balanceIS;
mapping(address => mapping(address =>uint256 ))private allowed;


    constructor()
    {
        totalSupply_ = 10000000000000000000000000000 ;
        balanceIS[msg.sender] = totalSupply_;
        owner = msg.sender;
    }
    modifier onlyOwner{
        owner = msg.sender;
        _;
    }

    function totalSupply() external view returns(uint256){

        return totalSupply_ ;
    }

    function balanceOf(address _tokenOwner) public view returns(uint256){

        return balanceIS[_tokenOwner] ;
    }

    function transfer(address _receiver, uint256 _amountOfToken) public  returns(bool){

        require (balanceIS[msg.sender] >0 || _amountOfToken < balanceIS[msg.sender], "Insufficient Balance");
        balanceIS[msg.sender] -= _amountOfToken ; 
        balanceIS[_receiver] += _amountOfToken ;    
        emit Transfer(msg.sender, _receiver, _amountOfToken );
        return true;
    }

    function allownce(address tokenOwner, address spender ) public view returns(uint256 remaining){

        return allowed [tokenOwner][spender];
    }

    function approve(address spender, uint256 amountOfToken) public returns(bool success){

        allowed [msg.sender][spender] = amountOfToken ;
        emit approval (msg.sender, spender, amountOfToken);
        return true;
    }

    function transferFrom(address from, address to, uint256 amountOfToken) public returns(bool success){

        uint256 allownces = allowed[from][msg.sender];
        require (balanceIS[from] >= amountOfToken && allownces >= amountOfToken );
        balanceIS[from] -= amountOfToken ;
        balanceIS[to]  += amountOfToken ;
        allowed [from][msg.sender] -= amountOfToken ;
        emit Transfer (from , to, amountOfToken);
        return true;
    }

    function mint(uint256 _amount) public {

        totalSupply_ = totalSupply_.add(_amount);
        balanceIS[msg.sender] = balanceIS[msg.sender].add(_amount);
        emit Transfer(address(0), msg.sender, _amount);
    }

    function burn(uint256 _value) public {

        totalSupply_ = totalSupply_.sub(_value);
        balanceIS[msg.sender] = balanceIS[msg.sender].sub(_value);
        emit Transfer(msg.sender, address(0), _value);
    }
    
    // function reservedToken() public  returns(uint256,uint256,uint256,uint256) {
    //     rewardReserved = totalSupply_ * 70 / 100;
    //     teamReserved = totalSupply_ * 10 / 100;
    //     marketingReserved = totalSupply_ * 15 /100;
    //     charityReserved = totalSupply_ * 5 / 100;
    //     return (rewardReserved,teamReserved,marketingReserved,charityReserved);
    // }

}
