// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IdleKey Interface
interface IIdleKey {
    function currentId() external view returns (uint256);
    function isSoldOut() external view returns (bool);
    function safeMintKeys(address to, uint256 count) external;
    function safeMintKey(address to) external returns (uint256);
    function burn(uint256 tokenId) external;
}
