// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// market contract enum interface
interface IHeroMarketEnum {
    function sellerSalesCount(address seller) external view returns (uint256);
    
    function saleTokenOfSellerByIndex(address seller, uint256 index) external view returns (uint256);

    function totalSaleTokens() external view returns (uint256);

    function saleTokenByIndex(uint256 index) external view returns (uint256);
}
