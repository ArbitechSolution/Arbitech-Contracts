// SPDX-License-Identifier:MIT
pragma solidity ^0.8.16;

interface IBEP20 {

    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function transfer(address receiver, uint256 tokenAmount) external  returns(bool);
    function transferFrom( address tokenOwner, address recipient, uint256 tokenAmount) external returns(bool);
    function allownce( address tokenOwner, address spender) external returns(uint256);
    function approve (address spender, uint256 tokenAmount ) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 tokenAmount);
    event approval( address indexed tokenOwner, address indexed spender, uint256 tokenAmount);
}
interface Staking {
   function getAddress() external view returns(address[] memory);

}

contract ATS is IBEP20 {
    
    Staking public Stake;
    string public constant tokenName = "Arbitech Solutions";
    string public constant tokenSymbol = "ATS";
    uint8 public  constant tokenDecimal  = 18;
    uint256 internal totalSupply_;
    address public owner;
    uint256 public rewardY;
    address[] public stakeholder;
    uint256 public rewardReserved ; //7000000000 ==>  70%
    uint256 public teamReserved ; // 1000000000 ==> 10%
    uint256 public marketingReserved; //1500000000 ==> 15%
    uint256 public charityReserved; //500000000 ==> 5%
    uint256 public rewardBurningPercentage = 3 ; // 3% of reward

    
    mapping(address => uint256) public balanceIS;
    mapping(address => mapping(address =>uint256 ))private allowed;
    mapping(address=> bool) public CheckAddress;

    constructor()
    {
        totalSupply_ = 10000000000 ether ;
        balanceIS[msg.sender] = totalSupply_;
        balanceIS[address(this)] = totalSupply_;
        owner = msg.sender;
        rewardReserved = totalSupply_ * 70 / 100 ;
        teamReserved = totalSupply_ * 10 / 100;
        marketingReserved = totalSupply_ * 15 / 100;
        charityReserved = totalSupply_ * 5 / 100;

    }

    modifier onlyOwner{
        require (msg.sender == owner,"caller not a Owner!");
        _;
    }

    modifier onlyContractAddress{
        require( CheckAddress[tx.origin] == true," you are not whitelisted!");
        _;
    }

    function getAccess(Staking _contract) public  onlyOwner {
        
        Stake = _contract;
    }

    function totalSupply() external view returns(uint256){

        return totalSupply_ ;
    }

    function balanceOf(address _tokenOwner) public view returns(uint256){

        return balanceIS[_tokenOwner] ;
    }

    function transfer(address _receiver, uint256 _amountOfToken) public  returns(bool){

        require (balanceIS[address(this)] >=  _amountOfToken, "Insufficient Balance");
       // require (balanceIS[msg.sender] >=  _amountOfToken, "Insufficient Balance");
        balanceIS[address(this)] -= _amountOfToken ; 
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

        totalSupply_ = totalSupply_+(_amount);
        balanceIS[msg.sender] = balanceIS[msg.sender]+(_amount);
        emit Transfer(address(0), msg.sender, _amount);
    }

    function burn(uint256 _value) public {

        totalSupply_ = totalSupply_ - (_value);
        balanceIS[msg.sender] = balanceIS[msg.sender]-(_value);
        emit Transfer(msg.sender, address(0), _value);
    }
  
    function stakeHoldersAddress() public  onlyOwner{

        for(uint256 i =0; i < Stake.getAddress().length; i++){
            if(CheckAddress[Stake.getAddress()[i]] = true){
                stakeholder.push(Stake.getAddress()[i]);
            }
        }
    }

    function burnReward(uint256 _value) public view returns(uint256) {

       uint256 burnpercentage = (_value * (rewardBurningPercentage)) / (100);
       uint256 reward = _value - (burnpercentage);
       return reward;
        
    }

    function updateBurningPercentage(uint256 _percentage) public  onlyOwner {

        rewardBurningPercentage = _percentage ; 
    }
    
    function WithdrawStakingReward( uint256 _value)  external  onlyContractAddress {

        rewardY =  burnReward(_value);
        transfer(tx.origin, rewardY);
        rewardReserved -= rewardY;
    }

    function getReward()public view returns(uint256){
        return rewardY;
    }
}