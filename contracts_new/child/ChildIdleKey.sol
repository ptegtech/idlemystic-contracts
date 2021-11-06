// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ChildMintableERC721.sol";
import "../utils/Counters.sol";
import "../interface/IIdleKey.sol";

contract ChildIdleKey is IIdleKey, ERC721Enumerable, Pausable, ChildMintableERC721
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint256 public MAX_SUPPLY = 48000;

    string public baseTokenURI;
    
    event KeyCreated(uint256 tokenId, address owner);
    event KeyCounterUpdated(uint256 tokenId);

    modifier onlyMinter() {
        _checkRole(MINTER_ROLE, msg.sender);
        _;
    }

    constructor() ChildMintableERC721("IdleKey", "IDK") {
        _initRoles();
    }

    function _initRoles() internal virtual {
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory uri) public virtual onlyMinter {
        baseTokenURI = uri;
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

    function currentId() public view override returns (uint256) {
        return _tokenIds.current();
    }

    function isSoldOut() public view override returns (bool) {
        return (_tokenIds.current() >= MAX_SUPPLY);
    }

    function incrementCounter(uint256 n) public whenNotPaused onlyMinter returns (uint256) {
        uint256 _currentId = _tokenIds.current();
        require(_currentId + n <= MAX_SUPPLY, "Over max supply");
        for (uint256 i=0; i<n; i++) {
            _tokenIds.increment();
            _currentId = _tokenIds.current();
            emit KeyCounterUpdated(_currentId);
        }
        return _currentId;
    }

    function safeMintKeys(address to, uint256 count) public whenNotPaused onlyMinter override {
        uint256 lastId = _tokenIds.current();
        require(count <= 10, "Count max: 10");
        require((lastId + count) < MAX_SUPPLY, "MAX SUPPLY");
        for (uint i=0; i<count; i++) {
            _tokenIds.increment();
            uint256 tokenId = _tokenIds.current();
            _safeMint(to, tokenId);
            emit KeyCreated(tokenId, to);
            emit KeyCounterUpdated(tokenId);
        }
    }

    function safeMintKey(address to) public whenNotPaused onlyMinter override returns (uint256) {
        uint256 lastId = _tokenIds.current();
        require(lastId < MAX_SUPPLY, "MAX SUPPLY");
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _safeMint(to, tokenId);
        emit KeyCreated(tokenId, to);
        emit KeyCounterUpdated(tokenId);
        return tokenId;
    }

    function _mint(address to, uint256 tokenId) internal virtual whenNotPaused override  {
        super._mint(to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual whenNotPaused override {
        super._burn(tokenId);
    }

    function burn(uint256 tokenId) public whenNotPaused override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, ChildMintableERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
}
