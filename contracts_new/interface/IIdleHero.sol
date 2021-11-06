// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IdleHero contract interface
interface IIdleHero {
    function safeMintHero(address to, uint256 dna) external returns (uint256);
    function addParentsChilds(uint256 parentIDA, uint256 parentIDB, uint256 tokenId) external;
    function heroDNA(uint256 tokenId) external view returns (uint256);
    function heroDetail(uint256 tokenId) external view returns (uint256 dna, uint256[] memory parents, uint256[] memory childs, uint256 bornCount);
    function burn(uint256 tokenId) external;
}
