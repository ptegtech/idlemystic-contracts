// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interface/IHeroGene.sol";
import "./interface/IIdleHero.sol";
import "./base/ERC721HeroCallerBase.sol";
import "./base/ERC20TokenCallerBase.sol";
import "./base/GeneCallerBase.sol";
import "./base/SecurityBase.sol";

contract HeroBorn is ERC721HeroCallerBase, ERC20TokenCallerBase, GeneCallerBase, SecurityBase {

    uint256[] private bornTokenPriceList;
    uint256 private bornTokenTotal;
    uint256 private bornTokenBase;
    uint256 private BORN_CD = 120 hours;
    mapping(uint256 => uint256) private bornTimeMap;

    constructor() {
        bornTokenPriceList = [100 ether, 200 ether, 300 ether, 500 ether, 800 ether, 1300 ether, 2100 ether];
    }

    function _checkHeroModifier(address caller) internal virtual override {
        _checkRole(MINTER_ROLE, caller);
    }

    function _checkTokenModifier(address caller) internal virtual override {
        _checkRole(MINTER_ROLE, caller);
    }

    function _checkRNGModifier(address caller) internal virtual override {
        _checkRole(MINTER_ROLE, caller);
    }

    function _checkGeneModifier(address caller) internal virtual override {
        _checkRole(MINTER_ROLE, caller);
    }

    function calcBornPrice(uint256 parentIDA, uint256 parentIDB) public view returns (uint256) {
        (, , , uint256 parent_a_borncount) = IIdleHero(_heroContract).heroDetail(parentIDA);
        (, , , uint256 parent_b_borncount) = IIdleHero(_heroContract).heroDetail(parentIDB);
        return _calcBornPrice(parent_a_borncount, parent_b_borncount);
    }

    function _calcBornPrice(uint256 parent_a_borncount, uint256 parent_b_borncount) internal view returns (uint256) {
        uint256 born_a_price = bornTokenPriceList[parent_a_borncount];
        uint256 born_b_price = bornTokenPriceList[parent_b_borncount];
        uint256 _bornTokenPrice = born_a_price + born_b_price;
        return _bornTokenPrice;
    }

    function bornHero(uint256 parentIDA, uint256 parentIDB) public whenNotPaused heroReady token20Ready geneReady {
        _bornHeroTo(msg.sender, parentIDA, parentIDB);
    }

    function bornHeroTo(address to, uint256 parentIDA, uint256 parentIDB) public whenNotPaused heroReady token20Ready geneReady {
        _bornHeroTo(to, parentIDA, parentIDB);
    }

    function setBornTokenBase(uint256 base) public whenNotPaused onlyMinter {
        bornTokenBase = base;
    }

    function getBornTokenTotal() public view returns (uint256)  {
        return bornTokenBase + bornTokenTotal;
    }

    function setBornCD(uint _hours) public whenNotPaused onlyMinter {
        BORN_CD = _hours * 1 hours;
    }

    function getBornCD() public view returns (uint) {
        return BORN_CD;
    }

    function withdrawTokens(address to, uint256 amount) public whenNotPaused onlyMinter {
        transferERC20Token(to, amount);
    }

    function _bornHeroTo(address to, uint256 parentIDA, uint256 parentIDB) internal whenNotPaused heroReady token20Ready geneReady {
        require(to != address(0), "New hero owner could not be NullAddress");
        require(parentIDA != parentIDB, "Parents should not be the same");
        require(block.timestamp >= (bornTimeMap[parentIDA] + BORN_CD), "Parent A not yet awake");
        require(block.timestamp >= (bornTimeMap[parentIDB] + BORN_CD), "Parent B not yet awake");

        (uint256 parent_a_dna, , , uint256 parent_a_borncount) = IIdleHero(_heroContract).heroDetail(parentIDA);
        (uint256 parent_b_dna, , , uint256 parent_b_borncount) = IIdleHero(_heroContract).heroDetail(parentIDB);

        require(IERC721(_heroContract).ownerOf(parentIDA) == msg.sender, "The sender is not the owner of NFT parent A");
        require(IERC721(_heroContract).ownerOf(parentIDB) == msg.sender, "The sender is not the owner of NFT parent B");
        require(parent_a_borncount <= 6, "Parents born count must less than 7");
        require(parent_b_borncount <= 6, "Parents born count must less than 7");

        uint256 _bornTokenPrice = _calcBornPrice(parent_a_borncount, parent_b_borncount);

        uint256 tokenBalance = balanceOfERC20Token(msg.sender);
        require(tokenBalance >= _bornTokenPrice, "Token balance not enought");

        uint256 allowanceToken = allowanceOfERC20Token(msg.sender, address(this));
        require(allowanceToken >= _bornTokenPrice, "Token allowance not enough");

        transferERC20TokenFrom(msg.sender, address(this), _bornTokenPrice);

        uint256 newDNA = IHeroGene(_geneContract).getBornDNA(parent_a_dna, parent_b_dna, to);
        uint256 tokenId = _safeMintHero(to, newDNA);

        IIdleHero(_heroContract).addParentsChilds(parentIDA, parentIDB, tokenId);
        bornTokenTotal += _bornTokenPrice;
        bornTimeMap[tokenId] = block.timestamp;
    }
}
