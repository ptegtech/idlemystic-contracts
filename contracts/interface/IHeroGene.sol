// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// market contract interface
interface IHeroGene {
    function getBornDNA(uint parent_a_dna, uint parent_b_dna, address owner) external returns(uint256 _dna);
}
