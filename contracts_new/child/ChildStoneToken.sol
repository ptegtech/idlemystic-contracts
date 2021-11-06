// contracts/StoneToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ChildMintableERC20.sol";

contract ChildStoneToken is ChildMintableERC20 {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyMinter() {
        _checkRole(MINTER_ROLE, msg.sender);
        _;
    }

    constructor() ChildMintableERC20("MagicStone", "MST") {
        _initRoles();
    }

     // init creator as admin role
    function _initRoles() internal virtual {
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function safeMint(address account, uint256 amount) public onlyMinter {
        _mint(account, amount);
    }

    function batchSafeMint(address[] memory account, uint256[] memory amount) public onlyMinter {
        for (uint i = 0; i < account.length; i++) {
            _mint(account[i], amount[i]);
        }
    }
   
    function grantMinter(address account) public virtual onlyRole(getRoleAdmin(MINTER_ROLE)) {
        _setupRole(MINTER_ROLE, account);
    }
}
