// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ERC20TokenCallerBase {

    address internal _token20Contract;

    constructor() {
    }

    modifier token20Ready() {
        require(_token20Contract != address(0), "Token contract is not ready");
        _;
    }

    function _checkTokenModifier(address caller) internal virtual;

    function token20Contract() public view returns (address) {
        return _token20Contract;
    }

    function setToken20Contract(address addr) public {
        _checkTokenModifier(msg.sender);
        _token20Contract = addr;
    }

    function transferERC20TokenFrom(address sender, address recipient, uint256 amount) internal token20Ready {
        IERC20(_token20Contract).transferFrom(sender, recipient, amount);
    }

    function transferERC20Token(address recipient, uint256 amount) internal token20Ready {
        IERC20(_token20Contract).transfer(recipient, amount);
    }

    function balanceOfERC20Token(address owner) internal view token20Ready returns (uint256) {
        return IERC20(_token20Contract).balanceOf(owner);
    }
    
    function allowanceOfERC20Token(address owner, address spender) internal view token20Ready returns (uint256) {
        return IERC20(_token20Contract).allowance(owner, spender);
    }

    function checkERC20TokenBalanceAndApproved(address owner, uint256 amount) internal view token20Ready {
        uint256 tokenBalance = balanceOfERC20Token(owner);
        require(tokenBalance >= amount, "Token balance not enough");

        uint256 allowanceToken = allowanceOfERC20Token(owner, address(this));
        require(allowanceToken >= amount, "Token allowance not enough");
    }
}
