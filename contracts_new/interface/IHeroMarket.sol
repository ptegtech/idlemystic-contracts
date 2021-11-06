// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// market contract interface
interface IHeroMarket {
    function getTokenOnSale(uint256 tokenId) external view returns (address seller, uint256 price, uint64 startedAt);

    function createSale(uint256 tokenId, uint256 price) external returns (uint256);

    function cancelSale(uint256 tokenId) external;

    function buySale(uint256 tokenId) external;

    function withdrawBalance(address to, uint256 amount) external;
}
