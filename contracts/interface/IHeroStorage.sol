// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IdleHero contract interface
interface IHeroStorage {
    function heroDNA(uint256 tokenId) external view returns (uint256);
    function heroDetail(uint256 tokenId) external view returns (uint256 dna, uint256[] memory parents, uint256[] memory childs, uint256 bornCount);
    function setHeroDNA(uint256 tokenId, uint256 dna) external;
    function addParentsChilds(uint256 parentIDA, uint256 parentIDB, uint256 tokenId) external;
}
