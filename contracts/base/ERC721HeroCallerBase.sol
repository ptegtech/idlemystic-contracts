// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interface/IIdleHero.sol";

abstract contract ERC721HeroCallerBase {

    address internal _heroContract;

    constructor() {
    }

    modifier heroReady() {
        require(_heroContract != address(0), "Hero contract is not ready");
        _;
    }

    function _checkHeroModifier(address caller) internal virtual;

    function heroContract() public view returns (address) {
        return _heroContract;
    }

    function setHeroContract(address addr) public {
        _checkHeroModifier(msg.sender);
        _heroContract = addr;
    }

    function ownerOfHero(uint256 tokenId) internal view heroReady returns (address)  {
        return IERC721(_heroContract).ownerOf(tokenId);
    }

    function _safeMintHero(address to, uint256 newDNA) internal returns (uint256) {
        return IIdleHero(_heroContract).safeMintHero(to, newDNA);
    }

    function _safeTransferHeroToken(address from, address to, uint256 tokenId) internal heroReady {
        IERC721(_heroContract).safeTransferFrom(from, to, tokenId);
    }
    
}
