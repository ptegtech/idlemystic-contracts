// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./base/SecurityBase.sol";
import "./interface/IIdleRNG.sol";


contract IdleRNG is IIdleRNG, VRFConsumerBase, SecurityBase {
    
    bytes32 internal keyHash;
    uint256 internal fee;
    
    mapping(bytes32 => address) private _randomFroms;
    mapping(address => bytes32) private _randomRequests;
    mapping(address => uint256) private _randomSeeds;
    
    event RNRequest(address from, bytes32 requestId);
    event RNResponse(address from, bytes32 requestId);
    /**
     * Constructor inherits VRFConsumerBase
     * 
     */
    constructor() VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token
        )
    {
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        fee = 0.0001 * 10 ** 18; // 0.0001 LINK (Varies by network)
    }
    
    /** 
     * Requests randomness 
     */
    function getRandomNumber(address from) public onlyMinter override {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 requestId = requestRandomness(keyHash, fee);
        _randomFroms[requestId] = from;
        _randomRequests[from] = requestId;
        emit RNRequest(from, requestId);
    }

    function hasRVFRequested(address from) public view override returns (bool) {
        bytes32 requestId = _randomRequests[from];
        return (requestId != "");
    }

    /*
    * just for unit test must delete when deploy on mainnet
    */
    function setRandomSeed(address from, uint256 randomness) public onlyMinter override {
        _randomSeeds[from] = randomness;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        address from = _randomFroms[requestId];
        require(from != address(0), "Random request not registered");
        _randomSeeds[from] = randomness;
        emit RNResponse(from, requestId);
    }

    function expandRandomness(address from, uint256 n) public view override returns (uint256[] memory expandedValues) {
        uint256 randomness = _randomSeeds[from];
        require(randomness != 0, "Random seed not ready");
        expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(block.difficulty, block.timestamp, randomness, i)));
        }
        return expandedValues;
    }

    function isSeedReady(address from) public view override returns (bool) {
        return _randomSeeds[from] != 0;
    }

    function withdrawLink(address to, uint256 amount) external virtual onlyMinter {
        LINK.transfer(to, amount);
    }
}
