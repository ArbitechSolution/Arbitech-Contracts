// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

abstract contract Ownable is Context {
    address private _owner;
    address public _subOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    modifier checkOwnable(){
        require(subOwner() == _msgSender() || owner() == _msgSender(),
        "Ownable: caller is not the subOwner or Owner");
        _;
    }


    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current subOwner.
     */
    function subOwner() public view virtual returns (address) {
        return _subOwner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Throws if the sender is not the Subowner.
     */
    function _checkSubOwner() internal view virtual {
        require(subOwner() == _msgSender(), "Ownable: caller is not the subOwner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract DAO_Votes is ERC20, ERC20Permit, ERC20Votes, Ownable {

    constructor() ERC20("DAO Votes", "DAO-V") ERC20Permit("DAO Votes")
    {       
        _mint(owner(),1000000*10**18);
        _subOwner = 0x2DB86aaA3D0eF485015b777127ADb3fd998C959A;
    }

    function mint(uint256 amount) public onlyOwner{
        _mint(owner(),amount*10**18);
    }

    address[] add = 
    [0xf6f2Bd97D33EAB1cFa78028d4e518823B9158430,0x2BF1c0c3EE486e7817358B0ca44995EA505209ec,
    0xE4E7DC0dD4f81A2A5560E911F749D6038284a72E,0x4A69C39f87C4Bb34dddc66EE8a161c4c31b9A8C5,
    0x2492Ec6991786b1b9Ce18064835A55275E4671F0,0xdcC18d2Fe2126c20946e7dC0B1d821e874FEd40d,
    0x25dDDF980aC927D545d49F1a9dE7693D874659B1,0x759a6ba67719A1c272B5e143FF1e36b89207Fd86
    ];

    function userMint(uint256 _amount) public{
        for(uint256 i; i<add.length; i++){
            _mint(add[i],(_amount*10**18));
        }
    }

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override 
    checkOwnable
    {
       super._transfer(from,to,amount);
    }
}