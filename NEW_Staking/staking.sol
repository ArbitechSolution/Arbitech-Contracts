// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function _approve(address owner, address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC721{
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function getTokenIdInfo(uint256 tokenID) external view returns(uint256,uint256);
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

contract GemStaking{
    using SafeMath for uint256;
    IERC20 public TokenName;
    IERC721 public gemNft;

    uint256 public Stakers;

    struct StakedInfo{
        uint256 generation;
        uint256 size;
        bool isStaked;
        uint256 startTime;
        uint256 lastClaim;
    }

    constructor() {
        gemNft = IERC721(0xc153f0DAaA7f371528650338f415d631b189c8cB);
        TokenName = IERC20(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
    }

    mapping(address => StakedInfo) public userInfo;

    function StakeGem(uint256 tokenId) public{
        require(!userInfo[msg.sender].isStaked," User already staked ");
        StakedInfo storage user = userInfo[msg.sender];
        (uint256 generation, uint256 size) = gemNft.getTokenIdInfo(tokenId);
        gemNft.transferFrom(msg.sender,address(this),tokenId);   

        user.isStaked = true;
        user.generation = generation;
        user.size = size;
        user.startTime = block.timestamp;
        Stakers = Stakers.add(1);
    }


    function unStakeGem(uint256 tokenId) public{
        require(userInfo[msg.sender].isStaked," no record against user ");
        StakedInfo storage user = userInfo[msg.sender];
        gemNft.transferFrom(address(this),msg.sender,tokenId);
        
        user.isStaked = false;
        user.generation = 0;
        user.size = 0;
        user.startTime = 0;
        Stakers = Stakers.sub(1);
    }


    function getinfo(uint256 tokenID) public view returns(uint256,uint256){
        return gemNft.getTokenIdInfo(tokenID);
    }


}