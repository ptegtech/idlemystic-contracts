// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ChildMintableERC721.sol";
import "../utils/Counters.sol";
import "../interface/IIdleHero.sol";
import "../interface/IHeroStorage.sol";

contract ChildIdleHero is IIdleHero, ERC721Enumerable, Pausable, ChildMintableERC721
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    address private _heroStorage;
    string public baseTokenURI;

    // minting Nft to chain in pre-sale, after NFT ready preMintFlag must always false;
    bool preMintFlag = true;

    struct NFTHero {
        uint256 dna;
        uint256[] parents;
        uint256[] childs;
        uint256 bornCount;
    }

    event HeroCreated(uint256 tokenId, address owner, uint256 dna);
    event BornUpdate(uint256 tokenId, uint256[] parents, uint256[] childs, uint256 bornCount);

    modifier onlyMinter() {
        _checkRole(MINTER_ROLE, msg.sender);
        _;
    }

    modifier storageReady() {
        require(_heroStorage != address(0));
        _;
    }

    constructor()
        ChildMintableERC721("IdleHero", "IDH") {
        _initRoles();
    }

    function _initRoles() internal virtual {
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function grantMinter(address account) public virtual onlyRole(getRoleAdmin(MINTER_ROLE)) {
        _setupRole(MINTER_ROLE, account);
    }

    function pause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _pause();
    }

    function unpause() public virtual {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _unpause();
    }

    function heroStorage() public view returns (address) {
        return _heroStorage;
    }

    function setHeroStorage(address to) public onlyMinter {
        _heroStorage = to;
    }

    function closePreMintFlag() public onlyMinter {
        preMintFlag = false;
    }

    function preMintHero(address to, uint256 _tokenId, uint256 dna) public whenNotPaused storageReady onlyMinter returns (uint256) {
        require(preMintFlag == true, "can't mint nft, pre-minting flag alreay closed");
        _safeMint(to, _tokenId);
        _setHeroDNA(_tokenId, dna);
        emit HeroCreated(_tokenId, to, dna);
        return _tokenId;
    }

    function setBaseCounter(uint256 _value) public onlyMinter {
        require(preMintFlag == true, "can't set tokenId number, pre-minting flag alreay closed");
        _tokenIds.set(_value);
    }

    function safeMintHero(address to, uint256 dna) public whenNotPaused storageReady onlyMinter override returns (uint256) {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _safeMint(to, tokenId);
        _setHeroDNA(tokenId, dna);
        emit HeroCreated(tokenId, to, dna);
        return tokenId;
    }

    function _setHeroDNA(uint256 tokenId, uint256 dna) internal whenNotPaused storageReady onlyMinter {
        IHeroStorage(_heroStorage).setHeroDNA(tokenId, dna);
    }

    function heroDetail(uint256 tokenId) public view override storageReady returns (
        uint256 dna,
        uint256[] memory parents,
        uint256[] memory childs,
        uint256 bornCount
    ) {
        require(_exists(tokenId), "ERC721: nonexistent token");
        return IHeroStorage(_heroStorage).heroDetail(tokenId);
    }

    function heroDNA(uint256 tokenId)
        public
        view
        override
        storageReady
        returns (uint256)
    {
        require(_exists(tokenId), "ERC721: nonexistent token");
        return IHeroStorage(_heroStorage).heroDNA(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ChildMintableERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _mint(address to, uint256 tokenId) internal virtual whenNotPaused override  {
        super._mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual whenNotPaused override {
        super._burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function burn(uint256 tokenId) public whenNotPaused override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function setBaseURI(string memory uri) public virtual onlyMinter {
        baseTokenURI = uri;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual whenNotPaused override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function addParentsChilds(uint256 parentIDA, uint256 parentIDB, uint256 tokenId) public whenNotPaused storageReady onlyMinter override {
        IHeroStorage(_heroStorage).addParentsChilds(parentIDA, parentIDB, tokenId);
        (, uint256[] memory _t_parents, uint256[] memory _t_childs, uint256 _t_born_count) = IHeroStorage(_heroStorage).heroDetail(tokenId);
        (, uint256[] memory _a_parents, uint256[] memory _a_childs, uint256 _a_born_count) = IHeroStorage(_heroStorage).heroDetail(parentIDA);
        (, uint256[] memory _b_parents, uint256[] memory _b_childs, uint256 _b_born_count) = IHeroStorage(_heroStorage).heroDetail(parentIDB);
        emit BornUpdate(tokenId, _t_parents, _t_childs, _t_born_count);
        emit BornUpdate(parentIDA, _a_parents, _a_childs, _a_born_count);
        emit BornUpdate(parentIDB, _b_parents, _b_childs, _b_born_count);
    }
}
