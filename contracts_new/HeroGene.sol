// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interface/IHeroGene.sol";
import "./base/RNGCallerBase.sol";
import "./base/SecurityBase.sol";
import "./utils/Integers.sol";
import "./utils/ExStrings.sol";
import "./HeroGeneShowSkill.sol";

contract HeroGene is IHeroGene, RNGCallerBase, SecurityBase {
    using ExStrings for string;
    using Integers for uint256;

    // bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address _HeroGeneShowSkillContract;

    struct RandStruct {
        uint[] RandIntList;
        uint index;
    }

    mapping(address => RandStruct) private RandMap;

    constructor() {
    }

    function getHeroGeneShowSkillContract() public view returns (address) {
        return _HeroGeneShowSkillContract;
    }

    function setHeroGeneShowSkillContract(address addr) public onlyMinter {
        _HeroGeneShowSkillContract = addr;
    }

    function _checkRNGModifier(address caller) internal virtual override {
        _checkRole(MINTER_ROLE, caller);
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

    function get_rand_int(uint x, uint step, address owner) internal returns(uint mold){
        if (x == 0) {
            return step;
        }
        if (RandMap[owner].index == 0) {
            RandStruct memory rand_struct;
            rand_struct.RandIntList = _expandRandomness(owner, 6);
            rand_struct.index == 1;
            RandMap[owner] = rand_struct;
        }
        uint v = RandMap[owner].RandIntList[RandMap[owner].index];
        mold = v%(x) + step;
        if (RandMap[owner].index >= 2){
            RandMap[owner].RandIntList = _expandRandomness(owner, 6);
            RandMap[owner].index = 1;
            return mold;
        }
        RandMap[owner].index += 1;
        return mold;
    }

    struct ParentADNA{
        string batchA;
        string unitA;
        string campA;
        string attrA;
        string showA;
        string skillA;
        string showA_r1;
        string skillA_r1;
        string showA_r2;
        string skillA_r2;
    }

    struct ParentBDNA{
        string batchB;
        string unitB;
        string campB;
        string attrB;
        string showB;
        string skillB;
        string showB_r1;
        string skillB_r1;
        string showB_r2;
        string skillB_r2;
    }

    struct BornDNAInfo{
        string batchC;
        string unitC;
        string campC;
        string attrC;
        string showC;
        string skillC;
        string showC_r1;
        string skillC_r1;
        string showC_r2;
        string skillC_r2;
    }

    struct Attr{
        uint attrA_health;
        uint attrA_speed;
        uint attrA_skill;
        uint attrA_mood;
        uint attrB_health;
        uint attrB_speed;
        uint attrB_skill;
        uint attrB_mood;
        uint attrC_health;
        uint attrC_speed;
        uint attrC_skill;
        uint attrC_mood;
    }

    function get_unit_or_camp(string memory unitA, string memory unitB, address owner, uint256 limit) internal returns(string memory){
        uint r = get_rand_int(100000, 1, owner);
        if (r <= limit) {
            return unitA;
        } else {
            return unitB;
        }
    }

    function get_attr(string memory attrA, string memory attrB) internal pure returns(string memory res){
        Attr memory attr;
        attr.attrA_health = parseIntSelf(attrA._substring(2, 0));
        attr.attrA_speed = parseIntSelf(attrA._substring(2, 2));
        attr.attrA_skill = parseIntSelf(attrA._substring(2, 4));
        attr.attrA_mood = parseIntSelf(attrA._substring(2, 6));
        attr.attrB_health = parseIntSelf(attrB._substring(2, 0));
        attr.attrB_speed = parseIntSelf(attrB._substring(2, 2));
        attr.attrB_skill = parseIntSelf(attrB._substring(2, 4));
        attr.attrB_mood = parseIntSelf(attrB._substring(2, 6));

        attr.attrC_health = (attr.attrA_health + attr.attrB_health)/2;
        attr.attrC_speed = (attr.attrA_speed + attr.attrB_speed)/2;
        attr.attrC_skill = (attr.attrA_skill + attr.attrB_skill)/2;
        attr.attrC_mood = (attr.attrA_mood + attr.attrB_mood)/2;
        uint attr_total = attr.attrC_health + attr.attrC_speed + attr.attrC_skill + attr.attrC_mood;
        uint add = 140 - attr_total;
        while (add > 0) {
            add = add - 1;
            if (attr.attrC_health < 43) {
                attr.attrC_health = attr.attrC_health + 1;
                continue;
            }
            if (attr.attrC_speed < 43) {
                attr.attrC_speed = attr.attrC_speed + 1;
                continue;
            }
            if (attr.attrC_skill < 43) {
                attr.attrC_skill = attr.attrC_skill + 1;
                continue;
            }          
            if (attr.attrC_mood < 43) {
                attr.attrC_mood = attr.attrC_mood + 1;
                continue;
            }
        }
        res = Integers.toString(attr.attrC_health);
        res = res.concat(Integers.toString(attr.attrC_speed));
        res = res.concat(Integers.toString(attr.attrC_skill));
        res = res.concat(Integers.toString(attr.attrC_mood));
        return res;
    }

    function getBornDNA(uint256 parent_a_dna, uint256 parent_b_dna, address owner) public override returns(uint256 _dna) {
        bool isSeedReady = isRNGSeedReady(owner);
        require(isSeedReady, "RNG seed is not ready");

        string memory parentA_dna = Integers.toString(parent_a_dna);
        string memory parentB_dna = Integers.toString(parent_b_dna);
        ParentADNA memory ParentA;
        ParentBDNA memory ParentB;
        BornDNAInfo memory DNA;

        ParentA.batchA = parentA_dna._substring(2, 0); // 2
        ParentA.unitA = parentA_dna._substring(3, 2);  //3
        ParentA.campA = parentA_dna._substring(2, 5);  //2
        ParentA.attrA = parentA_dna._substring(8, 7); //8
        ParentA.showA = parentA_dna._substring(12, 15); //12
        ParentA.skillA = parentA_dna._substring(8, 27); //8
        ParentA.showA_r1 = parentA_dna._substring(12, 35); //12
        ParentA.skillA_r1 = parentA_dna._substring(8, 47); //8
        ParentA.showA_r2 = parentA_dna._substring(12, 55); // 12
        ParentA.skillA_r2 = parentA_dna._substring(8, 67); // 8

        ParentB.batchB = parentB_dna._substring(2, 0); // 2
        ParentB.unitB = parentB_dna._substring(3, 2);  //3
        ParentB.campB = parentB_dna._substring(2, 5);  //2
        ParentB.attrB = parentB_dna._substring(8, 7); //8
        ParentB.showB = parentB_dna._substring(12, 15); //12
        ParentB.skillB = parentB_dna._substring(8, 27); //8
        ParentB.showB_r1 = parentB_dna._substring(12, 35); //12
        ParentB.skillB_r1 = parentB_dna._substring(8, 47); //8
        ParentB.showB_r2 = parentB_dna._substring(12, 55); // 12
        ParentB.skillB_r2 = parentB_dna._substring(8, 67); // 8

        DNA.batchC = "10";
        DNA.unitC = get_unit_or_camp(ParentA.unitA, ParentB.unitB, owner, 70000);
        DNA.campC = get_unit_or_camp(ParentA.campA, ParentB.campB, owner, 50000);
        DNA.attrC = get_attr(ParentA.attrA, ParentB.attrB);
        string[6] memory show_skill= HeroGeneShowSkill(_HeroGeneShowSkillContract).get_show_skill([ParentA.showA, ParentA.skillA, ParentB.showB, ParentB.skillB,
                        ParentA.showA_r1, ParentA.skillA_r1, ParentA.showA_r2, ParentA.skillA_r2,
                        ParentB.showB_r1, ParentB.skillB_r1, ParentB.showB_r2, ParentB.skillB_r2], owner);

        string memory dna = DNA.batchC.concat(DNA.unitC);
        dna = dna.concat(DNA.campC);
        dna = dna.concat(DNA.attrC);
        dna = dna.concat(show_skill[0]);
        dna = dna.concat(show_skill[1]);
        dna = dna.concat(show_skill[2]);
        dna = dna.concat(show_skill[3]);
        dna = dna.concat(show_skill[4]);
        dna = dna.concat(show_skill[5]);
        _dna = parseIntSelf(dna);
    }
}
