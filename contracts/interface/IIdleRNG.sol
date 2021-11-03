// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// contract interface
interface IIdleRNG {
    function getRandomNumber(address from) external;

    function expandRandomness(address from, uint256 n) external returns (uint256[] memory expandedValues);

    function isSeedReady(address from) external view returns (bool);

    function hasRVFRequested(address from) external view  returns (bool);

    function setRandomSeed(address addr, uint256 randomness) external;
}