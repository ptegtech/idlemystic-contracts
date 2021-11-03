// contracts/StoneToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DummyMintableERC20.sol";

contract DummyStoneToken is DummyMintableERC20 {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyMinter() {
        _checkRole(MINTER_ROLE, msg.sender);
        _;
    }

    constructor() DummyMintableERC20("MagicStone", "MST") {
        _initRoles();
    }

     // init creator as admin role
    function _initRoles() internal virtual {
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function safeMint(address account, uint256 amount) public onlyMinter {
        _mint(account, amount);
    }

   
    function grantMinter(address account) public virtual onlyRole(getRoleAdmin(MINTER_ROLE)) {
        _setupRole(MINTER_ROLE, account);
    }
}
