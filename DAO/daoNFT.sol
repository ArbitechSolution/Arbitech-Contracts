// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract DAO_NFT is ERC721, ERC721Enumerable, Pausable, Ownable, ERC721Burnable {
    IERC20 public ERC20Votes;
    uint256 public daoVotesPerNft = 2E18;

    constructor() ERC721("DAO NFT", "DAO NFT") {
        ERC20Votes = IERC20(0x359A4781a794286565D7EF26a6E2996B52803c35);
    }

    function pauseContract() public onlyOwner {
        _pause();
    }

    function unpauseContract() public onlyOwner {
        _unpause();
    }

    function safeMintWithCount(uint256 count)
    public
    onlyOwner
    {       for(uint256 i;i<count;i++)
        {       _safeMint(owner(), totalSupply() + 1 );      }
    }

    function walletOfOwner(address _owner)
    public view 
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
            for (uint256 i; i < ownerTokenCount; i++)
            {tokenIds[i] = tokenOfOwnerByIndex(_owner, i);}
            return tokenIds;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId)
        internal override 
    onlyOwner
    {
        ERC20Votes.transfer(to,daoVotesPerNft);
        super._transfer(from,to,tokenId);
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}