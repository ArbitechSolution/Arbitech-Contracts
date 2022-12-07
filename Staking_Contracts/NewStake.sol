// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
// Importing required files
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// Contract
contract stakingToken is ERC20{
    using SafeMath for uint256;
    address[] public stakeholders;
    mapping(address => uint256) public stakes;
    // mapping(address => uint256) public reward;
// Constructor
    constructor (address _owner, uint256 _supply){
    _mint(_owner, _supply);
    }
// Checking that the caller is stakeholder or not
    function isStakeholder(address _address) public returns(bool, uint256){
        for(uint256 i = 0; i <= stakeholders.length; i += 1){
            if (_address == stakeholders[i]){
                return (true, i);
            }
            return (false, 0);
        }
    }
    // 
    function addStakeholder(address _stakeholder) public{
        (bool _isStakeholder) = isStakeholder(_stakeholder);
        if (!_isStakeholder) stakeholder.push(_stakeholder);
    }
    function removeStakeholder(address _stakeholder) public {
        (bool _isStakeholder, uint256 i) = isStakeholder(_isStakeholder);
        if(_isStakeholder){
            stakeholder[i] = stakeholder[stakeholder.length -1];
            stakeholder.pop();
            }
    }
    function stakeOf(address _stakeholder) public view returns(uint256){
        return stakes[_stakeholder];
    }
    function createStake(uint256 _stake) public{
        _burn(msg.sender, _stake); // ??
        if(stakes[msg.sender] == 0) addStakeholder(msg.sender); // if True
        stakes[msg.sender] = stakes[msg.sender].add(_stake);
    }
    // Subtract the value of stack of that user if its available 
    // Also delete that stakeholder from staks

    function removeStake(uint256 _stake) public{
        stakes[msg.sender] = stakes[msg.sender].sub[_stake];
        if(stakes[msg.sender] == 0) removeStakeholder(msg.sender);
        _mint(msg.sender, _stake);
    }
}