// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base/SecurityBase.sol";
import "../interface/IHeroStorage.sol";

contract HeroStorage is IHeroStorage, SecurityBase
{
    // Mapping from token ID to hero dna
    mapping(uint256 => NFTHero) private _heroMap;

    bool preMintFlag = true;

    struct NFTHero {
        uint256 dna;
        uint256[] parents;
        uint256[] childs;
        uint256 bornCount;
    }

    constructor() {
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _heroMap[tokenId].dna != 0;
    }

    function setHeroDNA(uint256 tokenId, uint256 dna) external override onlyMinter {
        NFTHero memory nfthero;
        nfthero.dna = dna;
        nfthero.bornCount = 0;
        _heroMap[tokenId] = nfthero;
    }

    function heroDetail(uint256 tokenId) public view override returns (
        uint256 dna,
        uint256[] memory parents,
        uint256[] memory childs,
        uint256 bornCount
    ) {
        require(_exists(tokenId), "Nonexistent token");
        dna = _heroMap[tokenId].dna;
        parents = _heroMap[tokenId].parents;
        childs = _heroMap[tokenId].childs;
        bornCount = _heroMap[tokenId].bornCount;
    }

    function heroDNA(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        require(_exists(tokenId), "Nonexistent token");
        return _heroMap[tokenId].dna;
    }

    function addParentsChilds(uint256 parentIDA, uint256 parentIDB, uint256 tokenId) public onlyMinter override {
        _heroMap[tokenId].parents = [parentIDA, parentIDB];
        _heroMap[parentIDA].bornCount++;
        _heroMap[parentIDB].bornCount++;
        _heroMap[parentIDA].childs.push(tokenId);
        _heroMap[parentIDB].childs.push(tokenId);
    }
}
