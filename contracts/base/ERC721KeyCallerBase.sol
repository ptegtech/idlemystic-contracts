// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../interface/IIdleKey.sol";

abstract contract ERC721KeyCallerBase {

    address internal _keyContract;

    constructor() {
    }

    modifier keyReady() {
        require(_keyContract != address(0), "Key contract is not ready");
        _;
    }

    function _checkKeyModifier(address caller) internal virtual;

    function keyContract() public view returns (address) {
        return _keyContract;
    }

    function setKeyContract(address addr) public {
        _checkKeyModifier(msg.sender);
        _keyContract = addr;
    }

    function balanceOfKey(address owner) internal view keyReady returns (uint256) {
        return IERC721Enumerable(_keyContract).balanceOf(owner);
    }
    
    function isApprovedForAllKeys(address owner, address operator) internal view keyReady returns (bool) {
        return IERC721Enumerable(_keyContract).isApprovedForAll(owner, operator);
    }

    function keyOfOwnerByIndex(address owner, uint256 index) internal view keyReady returns (uint256) {
        return IERC721Enumerable(_keyContract).tokenOfOwnerByIndex(owner, index);
    }

    function burnKey(uint256 tokenId) internal keyReady {
        IIdleKey(_keyContract).burn(tokenId);
    }

    function isKeySoldOut() internal view keyReady returns (bool) {
        return IIdleKey(_keyContract).isSoldOut();
    }

    function safeMintKey(address to) internal keyReady {
        IIdleKey(_keyContract).safeMintKey(to);
    }

    function safeMintKeys(address to, uint256 count) internal keyReady {
        IIdleKey(_keyContract).safeMintKeys(to, count);
    }
}
