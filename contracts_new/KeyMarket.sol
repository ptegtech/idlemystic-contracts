// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./base/ERC721KeyCallerBase.sol";
import "./base/ERC20TokenCallerBase.sol";
import "./base/SecurityBase.sol";

contract KeyMarket is ERC721KeyCallerBase, ERC20TokenCallerBase, SecurityBase {

    uint256 private _keyPrice;

    event KeyPriceChanged(uint256 newPrice);

    constructor() {
        _keyPrice = 1 ether;
    }

    function _checkKeyModifier(address caller) internal virtual override {
        _checkRole(MINTER_ROLE, caller);
    }

    function _checkTokenModifier(address caller) internal virtual override {
        _checkRole(MINTER_ROLE, caller);
    }

    function keyPrice() public view returns (uint256) {
        return _keyPrice;
    }

    function setKeyPrice(uint256 price) public onlyMinter {
        _keyPrice = price;
        emit KeyPriceChanged(_keyPrice);
    }

    function buyKey() public whenNotPaused {
        bool isKeySoldOut = isKeySoldOut();
        require(!isKeySoldOut, "Key has been sold out");

        checkERC20TokenBalanceAndApproved(msg.sender, _keyPrice);

        transferERC20TokenFrom(msg.sender, address(this), _keyPrice);

        safeMintKey(msg.sender);
    }

    function buyKeys(uint256 count) public whenNotPaused {
        bool isKeySoldOut = isKeySoldOut();
        require(!isKeySoldOut, "Key has been sold out");
        require(count <= 10, "Max 10 keys in one time");

        uint256 totalPrice = _keyPrice * count;

        checkERC20TokenBalanceAndApproved(msg.sender, totalPrice);

        transferERC20TokenFrom(msg.sender, address(this), totalPrice);
        
        safeMintKeys(msg.sender, count);
    }

    function _transferBalance(address to, uint256 amount) internal {
        transferERC20Token(to, amount);
    }

    function withdrawBalance(address to, uint256 amount) external onlyMinter {
        uint256 currentBalance = balanceOfERC20Token(address(this));
        require(amount <= currentBalance, "No enough balance");
        _transferBalance(to, amount);
    }

}
