pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import "./GrothSahai.sol";

contract TestGS {

    struct SampleStruct{ uint x; uint y; }
    function passStructSample(SampleStruct memory s) public view returns (bool) {
        return s.x == 1;
    }

    function verifyProof(GrothSahai.GSInstance memory inst,
                         GrothSahai.GSParams memory params,
                         GrothSahai.GSCom memory com,
                         GrothSahai.GSProof memory proof) public view returns (bool) {
        return GrothSahai.verifyProof(inst, params, com, proof);
    }

    function dummyFunction(bool a) public view returns (bool) {
        return a;
    }
}
