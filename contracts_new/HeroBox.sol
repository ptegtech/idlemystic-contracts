// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/IIdleRNG.sol";
import "./base/ERC721HeroCallerBase.sol";
import "./base/ERC721KeyCallerBase.sol";
import "./base/ERC20TokenCallerBase.sol";
import "./base/RNGCallerBase.sol";
import "./base/SecurityBase.sol";
import "./utils/ExStrings.sol";
import "./utils/Integers.sol";

contract HeroBox is ERC721HeroCallerBase, ERC721KeyCallerBase, ERC20TokenCallerBase, RNGCallerBase, SecurityBase {
    
    using ExStrings for string;
    using Integers for uint256;

    uint256 private _batchStart = 0;
    uint256 private _batchRange = 3;
    bool private _firstSale = true;

    constructor() {
    }

    struct HeroInfo {
        string hero_head;
        string hero_hand;
        string hero_body;
        string hero_weapon;
        string hero_plat;
        string hero_flag;

        string s_head;
        string s_hand;
        string s_body;
        string s_weapon;

        string _batch;
        string unit;
        string camp;
        string attr;
        string showD;
        string skillD;
        string showR1;
        string skillR1;
        string showR2;
        string skillR2;
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

    function _checkKeyModifier(address caller) internal virtual override {
        _checkRole(MINTER_ROLE, caller);
    }

    function compareStringsbyBytes(string memory s1, string memory s2) private pure returns(bool){
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    struct RandStruct {
        uint[] RandIntList;
        uint index;
    }
    mapping(address => RandStruct) private RandMap;

    function get_rand_int(uint x, uint step) internal returns(uint mold){
        if (x == 0) {
            return step;
        }
        if (RandMap[msg.sender].index == 0) {
            RandStruct memory rand_struct;
            rand_struct.RandIntList = _expandRandomness(msg.sender, 80);
            rand_struct.index == 1;
            RandMap[msg.sender] = rand_struct;
        }
        uint v = RandMap[msg.sender].RandIntList[RandMap[msg.sender].index];
        mold = v%(x) + step;
        if (RandMap[msg.sender].index >= 49){
            RandMap[msg.sender].RandIntList = _expandRandomness(msg.sender, 80);
            RandMap[msg.sender].index = 1;
            return mold;
        }
        RandMap[msg.sender].index += 1;
        return mold;
    }

    function parseIntSelf(string memory s) private pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) {
            if (uint(uint8(b[i])) >= 48 && uint(uint8(b[i])) <= 57) {
                result = result * 10 + (uint(uint8(b[i])) - 48);
            }
        }
        return result;
    }

    function get_hero_unit(uint batch) internal returns(string memory res) {
        require(batch >= 11, "hero batch not allow");
        uint unit = 101 + 3*(batch-11)+ get_rand_int(3, 0);
        res = Integers.toString(unit);
        return res;
    }

    function get_hero_camp() internal returns(string memory res) {
        uint rand = get_rand_int(6, 11);
        res = Integers.toString(rand);
        return res;
    }

    function get_hero_attr() internal returns(string memory res){
        uint health = get_rand_int(17, 27);
        uint speed = get_rand_int(17, 27);
        uint sum_avg = (140 - health - speed) / 2;
        uint skill = 0;
        if (sum_avg >= 35) {
            uint _scope = (43 - sum_avg) * 2;
            skill = 43 - get_rand_int(_scope, 0);
        }
        if (sum_avg < 35){
            uint _scope = (sum_avg - 27) * 2;
            skill = 27 + get_rand_int(_scope, 0);
        }
        uint mood = 140 - health - speed - skill;
        uint total = health+speed+skill+mood;
        require(total == 140, "total error");
        res = Integers.toString(health);
        res = res.concat(Integers.toString(speed));
        res = res.concat(Integers.toString(skill));
        res = res.concat(Integers.toString(mood));
        return res;
    }


    function get_hero_head(bool first) internal returns(uint) {
        uint is_legend = get_rand_int(100, 1);
        if (is_legend <= 15 && first == true) {
            return 51;
        }
        uint res = 10 + get_rand_int(4, 1);
        return res;
    }

    function get_hero_hand(bool first) internal returns(uint) {
        uint is_legend = get_rand_int(100, 1);
        if (is_legend <= 15 && first == true) {
            return 61;
        }
        uint res = 20 + get_rand_int(6, 1);
        return res;
    }

    function get_hero_body(bool first) internal returns(uint) {
        uint is_legend = get_rand_int(100, 1);
        if (is_legend <= 15 && first == true) {
            return 71;
        }
        uint res = 30 + get_rand_int(6, 1);
        return res;
    }

    function get_hero_weapon(bool first) internal returns(uint) {
        uint is_legend = get_rand_int(100, 1);
        if (is_legend <= 15 && first == true) {
            return 81;
        }
        uint res = 40 + get_rand_int(6, 1);
        return res;
    }

    function get_hero_plat() internal returns(uint) {
        uint res = get_rand_int(6, 1);
        return res;
    }

    function get_hero_flag() internal returns(uint)  {
        uint res = get_rand_int(6, 1);
        return res;
    }

    function get_heroShow(bool first) internal returns(string memory res) {
        HeroInfo memory hero_info;

        hero_info.hero_head = Integers.toString(get_hero_head(first));
        hero_info.hero_hand = Integers.toString(get_hero_hand(first));
        hero_info.hero_body = Integers.toString(get_hero_body(first));
        hero_info.hero_weapon = Integers.toString(get_hero_weapon(first));
        hero_info.hero_plat = Integers.toString(get_hero_plat());
        hero_info.hero_flag = Integers.toString(get_hero_flag());

        res = hero_info.hero_head.concat(hero_info.hero_hand);
        res = res.concat(hero_info.hero_body);
        res = res.concat(hero_info.hero_weapon);
        res = res.concat("0");
        res = res.concat(hero_info.hero_plat);
        res = res.concat("0");
        res = res.concat(hero_info.hero_flag);

        return res;
    }

    function get_hero_skill() internal returns(string memory res) {
        HeroInfo memory hero_info;
        hero_info.s_head = Integers.toString(get_rand_int(6, 1));
        hero_info.s_hand = Integers.toString(get_rand_int(6, 1));
        hero_info.s_body = Integers.toString(get_rand_int(6, 1));
        hero_info.s_weapon = Integers.toString(get_rand_int(6, 1));
        res = "0";
        res = res.concat(hero_info.s_head);
        res = res.concat("0");
        res = res.concat(hero_info.s_hand);
        res = res.concat("0");
        res = res.concat(hero_info.s_body);
        res = res.concat("0");
        res = res.concat(hero_info.s_weapon);

        return res;
    }

    function duplication(string memory a, string memory b, string memory c) private pure returns(bool) {
        uint x = parseIntSelf(a);
        uint y = parseIntSelf(b);
        uint z = parseIntSelf(c);
        if (x == y || x == z || y == z) {
            return true;
        }
        return false;
    }


    function generateDna(uint batch, bool first) internal returns(string memory dna){
        HeroInfo memory hero_info_dna;

        hero_info_dna._batch = Integers.toString(batch);
        hero_info_dna.unit = get_hero_unit(batch);
        hero_info_dna.camp =  get_hero_camp();
        hero_info_dna.attr = get_hero_attr();
        hero_info_dna.showD = get_heroShow(first);
        hero_info_dna.skillD = get_hero_skill();
        hero_info_dna.showR1 = get_heroShow(false);
        hero_info_dna.skillR1 = get_hero_skill();
        hero_info_dna.showR2 = get_heroShow(false);
        hero_info_dna.skillR2 = get_hero_skill();

        dna = hero_info_dna._batch.concat(hero_info_dna.unit);
        dna = dna.concat(hero_info_dna.camp);
        dna = dna.concat(hero_info_dna.attr);
        dna = dna.concat(hero_info_dna.showD);
        dna = dna.concat(hero_info_dna.skillD);
        dna = dna.concat(hero_info_dna.showR1);
        dna = dna.concat(hero_info_dna.skillR1);
        dna = dna.concat(hero_info_dna.showR2);
        dna = dna.concat(hero_info_dna.skillR2);
    }

    function getHeroBatch() public view returns (uint256 batchStart, uint256 batchRange) {
        batchStart = _batchStart;
        batchRange = _batchRange;
    }

    function isFirstSale() public view returns (bool) {
        return _firstSale;
    }

    function setHeroBatch(uint256 batchStart, uint256 batchRange) public onlyMinter {
       _batchStart = batchStart;
       _batchRange = batchRange;
    }

    function setFirstSale(bool first) public onlyMinter {
        _firstSale = first;
    }

    function _generatorDNA() internal returns (uint256 newDNA) {
        uint256 batch = 10 + _batchStart + get_rand_int(_batchRange, 1);
        string memory dna = generateDna(batch, _firstSale);
        newDNA = parseIntSelf(dna);
    }

    function openBox(address to) public whenNotPaused heroReady keyReady RNGReady {
        require(to != address(0), "New hero owner could not be NullAddress");

        uint256 keyBalance = balanceOfKey(msg.sender);
        require(keyBalance >= 1, "Key count not enought");

        bool isApproved = isApprovedForAllKeys(msg.sender, address(this));
        require(isApproved, "Keys has not been approved to box contract");

        bool isRNGSendReady = isRNGSeedReady(msg.sender);
        require(isRNGSendReady, "RNG seed is not ready");
        
        uint256 keyTokenId = keyOfOwnerByIndex(msg.sender, 0);
        burnKey(keyTokenId);

        uint256 newDNA = _generatorDNA();
        _safeMintHero(to, newDNA);
    }
}
