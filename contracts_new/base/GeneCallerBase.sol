// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interface/IHeroGene.sol";
import "./RNGCallerBase.sol";

abstract contract GeneCallerBase is RNGCallerBase {

    address internal _geneContract;

    constructor() {
    }

    modifier geneReady() {
        require(_geneContract != address(0), "Gene contract is not ready");
        _;
    }

    function _checkGeneModifier(address caller) internal virtual;

    function geneContract() public view returns (address) {
        return _geneContract;
    }

    function setGeneContract(address addr) public {
        _checkGeneModifier(msg.sender);
        _geneContract = addr;
    }

    function generateGene(uint256 dna_a, uint256 dna_b, address owner) internal geneReady returns (uint256) {
        uint256 newDNA = IHeroGene(_geneContract).getBornDNA(dna_a, dna_b, owner);
        return newDNA;
    }
    
}
