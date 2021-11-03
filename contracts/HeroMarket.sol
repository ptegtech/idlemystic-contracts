// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./base/ERC721HeroCallerBase.sol";
import "./base/ERC20TokenCallerBase.sol";
import "./base/SecurityBase.sol";
import "./interface/IHeroMarket.sol";
import "./interface/IHeroMarketEnum.sol";

/* Market Contract
** sell hero by fixed prie
*/
contract HeroMarket is IHeroMarket, IHeroMarketEnum, ERC721HeroCallerBase, ERC20TokenCallerBase, SecurityBase, ERC721Holder {

    struct Sale {
        address seller;
        uint256 price;
        uint64 startedAt;
    }

    // price limit
    uint256 private _PRICE_LIMIT;
    // min price
    uint256 private _minPrice;
    // min trade fee
    uint256 private _minFee;
    // trade fee pecentage
    uint8 private _tradeFee;
    // total trade fee receieved
    uint256 private _totalFeeAmount;

    mapping(uint256 => Sale) private tokenIdToSale;

    mapping(address => uint256) private _sellerSalesCount;
    mapping(address => mapping(uint256 => uint256)) private _sellerSaleTokens;
    mapping(uint256 => uint256) private _sellerSaleTokensIndex;

    uint256[] private _allSaleTokens;
    mapping(uint256 => uint256) private _allSaleTokensIndex;

    event SaleCreated(uint256 tokenId, uint256 price, address seller);
    event SaleSucceed(uint256 tokenId, uint256 price, address seller, address buyer);
    event SaleCancelled(uint256 tokenId, address seller);

    constructor() {
        _PRICE_LIMIT = 0.01 ether;
        _minPrice = 0.01 ether;
        _minFee = 0.001 ether;
        _tradeFee = 4;
        _totalFeeAmount = 0;
    }

    function _checkHeroModifier(address caller) internal virtual override {
        _checkRole(MINTER_ROLE, caller);
    }

    function _checkTokenModifier(address caller) internal virtual override {
        _checkRole(MINTER_ROLE, caller);
    }

    fallback() external payable {}

    receive() external payable {}

    function setMinPrice(uint256 to) public onlyMinter {
        require(to > _PRICE_LIMIT);
        _minPrice = to;
    }

    function getMinPrice() public view returns (uint256) {
        return _minPrice;
    }

    function setMinFee(uint256 to) public onlyMinter {
        require(to > _PRICE_LIMIT);
        _minFee = to;
    }

    function getMinFee() public view returns (uint256) {
        return _minFee;
    }

    function setTradeFee(uint8 to) public onlyMinter {
        require(to >= 1 && to < 100 );
        _tradeFee = to;
    }

    function getTradeFee() public view returns (uint256) {
        return _tradeFee;
    }

    function getTotalFeeAmount() public view returns (uint256) {
        return _totalFeeAmount;
    }

    function sellerSalesCount(address seller) public view override returns (uint256) {
        return _sellerSalesCount[seller];
    }

    function saleTokenOfSellerByIndex(address seller, uint256 index) public view override returns (uint256) {
        require(index < _sellerSalesCount[seller], "seller index out of bounds");
        return _sellerSaleTokens[seller][index];
    }

    function totalSaleTokens() public view override returns (uint256) {
        return _allSaleTokens.length;
    }

    function saleTokenByIndex(uint256 index) public view override returns (uint256) {
        require(index < _allSaleTokens.length, "global index out of bounds");
        return _allSaleTokens[index];
    }

    function _isOnSale(Sale storage sale) internal view returns (bool) {
        return (sale.startedAt > 0);
    }

    function _escrow(address _owner, uint256 tokenId) internal {
        if (_owner != address(this)) {
            _safeTransferHeroToken(_owner, address(this), tokenId);
        }
    }

    function _addSaleTokenToSellerEnumeration(address to, uint256 tokenId) private {
        uint256 length = _sellerSalesCount[to];
        _sellerSaleTokens[to][length] = tokenId;
        _sellerSaleTokensIndex[tokenId] = length;
        _sellerSalesCount[to] += 1;
    }

    function _addSaleTokenToAllEnumeration(uint256 tokenId) private {
        _allSaleTokensIndex[tokenId] = _allSaleTokens.length;
        _allSaleTokens.push(tokenId);
    }

    function _removeSaleTokenFromSellerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = _sellerSalesCount[from] - 1;
        uint256 tokenIndex = _sellerSaleTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _sellerSaleTokens[from][lastTokenIndex];
            _sellerSaleTokens[from][tokenIndex] = lastTokenId;
            _sellerSaleTokensIndex[lastTokenId] = tokenIndex;
        }

        _sellerSalesCount[from] -= 1;
        delete _sellerSaleTokensIndex[tokenId];
        delete _sellerSaleTokens[from][lastTokenIndex];
    }

    function _removeSaleTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allSaleTokens.length - 1;
        uint256 tokenIndex = _allSaleTokensIndex[tokenId];

        uint256 lastTokenId = _allSaleTokens[lastTokenIndex];

        _allSaleTokens[tokenIndex] = lastTokenId;
        _allSaleTokensIndex[lastTokenId] = tokenIndex;

        delete _allSaleTokensIndex[tokenId];
        _allSaleTokens.pop();
    }

    // add a hero on sale
    function _addSale(uint256 tokenId, Sale memory sale) internal {
        tokenIdToSale[tokenId] = sale;
        _addSaleTokenToSellerEnumeration(sale.seller, tokenId);
        _addSaleTokenToAllEnumeration(tokenId);
        emit SaleCreated(
            uint256(tokenId),
            uint256(sale.price),
            sale.seller
        );
    }
    
    // remove a hero from sale
    function _removeSale(uint256 tokenId) internal {
        Sale storage s = tokenIdToSale[tokenId];
        address seller = s.seller;
        _removeSaleTokenFromSellerEnumeration(seller, tokenId);
        _removeSaleTokenFromAllTokensEnumeration(tokenId);
        delete tokenIdToSale[tokenId];
    }

    // check whether the sender is owner
    function _checkMsgSenderMatchOwner(uint256 tokenId) internal view returns (bool) {
        address owner = ownerOfHero(tokenId);
        return (owner == msg.sender);
    }

    // add a hero on sale
    function createSale(uint256 tokenId, uint256 price) public whenNotPaused override returns (uint256) {
        require(_checkMsgSenderMatchOwner(tokenId), "Not hero owner");
        require(price >= _minPrice, "Unit price too low");
        address seller = msg.sender;
        _escrow(seller, tokenId);
        Sale memory sale = Sale(
            seller,
            price,
            uint64(block.timestamp)
        );
        _addSale(tokenId, sale);
        // return on sale hero count
        return _allSaleTokens.length - 1;
    }

    // get a hero sale details
    function getTokenOnSale(uint256 tokenId) public view override returns (
        address seller,
        uint256 price,
        uint64 startedAt
    ) {
        (seller, price, startedAt) = _getTokenOnSale(tokenId);
    }

    function getTokenTradeFee(uint256 tokenId) public view returns (uint256) {
        address seller;
        uint256 price;
        uint64 startedAt;
        (seller, price, startedAt) = _getTokenOnSale(tokenId);
        uint256 tradeFee = _calculateTradeFee(price);
        return tradeFee;
    }

    function _getTokenOnSale(uint256 tokenId) internal view returns (
        address seller,
        uint256 price,
        uint64 startedAt
    ) {
        Sale storage s = tokenIdToSale[tokenId];
        require(_isOnSale(s), "Token is not on sale");
        seller = s.seller;
        price = s.price;
        startedAt = s.startedAt;
    }

    // cancel a hero from sale
    function _cancelOnSale(uint256 tokenId, address seller) internal {
        // remove sale
        _removeSale(tokenId);
        // transfor the hero back to seller
        _safeTransferHeroToken(address(this), seller, tokenId);
        emit SaleCancelled(tokenId, seller);
    }

    function _cancelSale(uint256 tokenId) internal {
        Sale storage s = tokenIdToSale[tokenId];
        require(_isOnSale(s), "Token is not on sale");
        address seller = s.seller;
        require(msg.sender == seller);
        _cancelOnSale(tokenId, seller);
    }

    function _forceCancelSale(uint256 tokenId) internal {
        Sale storage s = tokenIdToSale[tokenId];
        require(_isOnSale(s), "Token is not on sale");
        address seller = s.seller;
        _cancelOnSale(tokenId, seller);
    }

    // calculate the trade fee
    function _calculateTradeFee(uint256 payment) internal view returns (uint256) {
        uint256 fee = payment * _tradeFee / 100;
        if (fee < _minFee) {
            fee = _minFee;
        }
        return fee;
    }

    // buy a hero on sale
    function _buySale(uint256 tokenId) internal whenNotPaused {
        require(msg.sender != address(0), "Invalid buyer");

        address seller;
        uint256 price;
        uint64 startedAt;
        (seller, price, startedAt) = _getTokenOnSale(tokenId);

        require(msg.sender != seller, "Could not buy your own item");

        checkERC20TokenBalanceAndApproved(msg.sender, price);

        transferERC20TokenFrom(msg.sender, address(this), price);

        // remove sale first
        _removeSale(tokenId);

        uint256 tradeFee = _calculateTradeFee(price);
        // calculate trade fee
        if (price > tradeFee) {
            _totalFeeAmount += tradeFee;
            uint256 leastAmount = price - tradeFee;
            // transfer least payment to seller
            _transferBalance(seller, leastAmount);
        } else {
            // if trade fee is less than min trade fee, no least fee to pay back to seller
            _totalFeeAmount += msg.value;
        }
        // transfer hero to buyer
        _safeTransferHeroToken(address(this), msg.sender, tokenId);
        emit SaleSucceed(tokenId, price, seller, msg.sender);
    }

    // cancel a hero from sale
    function cancelSale(uint256 tokenId) external override {
        _cancelSale(tokenId);
    }

    // buy a hero on sale
    function buySale(uint256 tokenId) external whenNotPaused override {
        _buySale(tokenId);
    }

    // withdraw balance
    function withdrawBalance(address to, uint256 amount) external onlyMinter override {
        uint256 currentBalance = balanceOfERC20Token(address(this));
        require(amount <= currentBalance, "No enough balance");
        _transferBalance(to, amount);
    }

    function _transferBalance(address to, uint256 amount) internal {
        transferERC20Token(to, amount);
    }

    function cancelLastSale(uint256 count) public onlyMinter {
        uint256 totalCount = totalSaleTokens();
        require(count <= totalCount);
        for (uint i=0; i<count; i++) {
            uint256 currentTotal = totalSaleTokens();
            uint256 lastTokenId = saleTokenByIndex(currentTotal - 1);
            _forceCancelSale(lastTokenId);
        }
    }
}
