// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IIdleRNG.sol";

abstract contract RNGCallerBase {

    address internal _RNGContract;

    constructor() {
    }

    modifier RNGReady() {
        require(_RNGContract != address(0), "RNG contract is not ready");
        _;
    }

    function _checkRNGModifier(address caller) internal virtual;

    function RNGContract() public view returns (address) {
        return _RNGContract;
    }

    function setRNGContract(address addr) public {
        _checkRNGModifier(msg.sender);
        _RNGContract = addr;
    }

    function isRNGSeedReady(address from) public view RNGReady returns (bool) {
        return IIdleRNG(_RNGContract).isSeedReady(from);
    }

    function hasRVFRequested(address from) public view returns (bool) {
        return IIdleRNG(_RNGContract).hasRVFRequested(from);
    }

    function generateRNGSeed() public virtual RNGReady {
        _generateRNGSeedTo(msg.sender);
    }

    function _generateRNGSeedTo(address from) internal RNGReady {
        IIdleRNG(_RNGContract).getRandomNumber(from);
    }

    function _expandRandomness(address from, uint256 n) internal RNGReady returns (uint256[] memory expandedValues) {
        return IIdleRNG(_RNGContract).expandRandomness(from, n);
    }
    
}
