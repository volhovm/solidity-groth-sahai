pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import "./GrothSahai.sol";
import "./EC.sol";

contract TestGS {

    struct SampleStruct{ uint x; uint y; }
    function passStructSample(SampleStruct memory s) public view returns (bool) {
        return s.x == 1;
    }

    event EDebug(string msg);
    event EDebug2(EC.G1Point p1);
    event EDebug3(EC.G2Point p1);

    function testNegate() public returns (bool) {
        if (!EC.pointEq(EC.Z1(), EC.scalar_mul(EC.P1(),0))) return false;
        if (!EC.pointEq(EC.Z1(), EC.scalar_mul(EC.scalar_mul(EC.P1(),100),0))) return false;
        if (!EC.pointEq(EC.Z1(), EC.addition(EC.scalar_mul(EC.P1(),100),
                                             EC.scalar_mul(EC.P1(),-100)))) return false;
        if (!EC.pointEq(EC.scalar_mul(EC.scalar_mul(EC.P1(), -10), -50),
                        EC.scalar_mul(EC.P1(), 500))) return false;
        if (!EC.pointEq(EC.P1(), EC.addition(EC.P1(),EC.Z1()))) return false;

        if (!EC.pointEq(EC.Z2(), EC.scalar_mul(EC.P2(),0))) return false;
        if (!EC.pointEq(EC.Z2(), EC.scalar_mul(EC.scalar_mul(EC.P2(),100),0))) return false;
        if (!EC.pointEq(EC.Z2(), EC.addition(EC.scalar_mul(EC.P2(),100),
                                             EC.scalar_mul(EC.P2(),-100)))) return false;
        if (!EC.pointEq(EC.scalar_mul(EC.scalar_mul(EC.P2(), -10), -50),
                        EC.scalar_mul(EC.P2(), 500))) return false;
        if (!EC.pointEq(EC.P2(), EC.addition(EC.P2(),EC.Z2()))) return false;

        return true;
    }

    function verifyProof1(GS.GSInstance memory inst,
                          int[] memory x0,
                          int[] memory y0,
                          int[][][] memory rst,
                          int[2][2][2] memory paramsRand
                         ) public returns (bool) {
        emit EDebug("Point1");
        EC.G1Point[] memory x = new EC.G1Point[](inst.m);
        EC.G2Point[] memory y = new EC.G2Point[](inst.n);
        for (uint i = 0; i < inst.m; i++) { x[i] = EC.scalar_mul(EC.P1(), x0[i]); }
        for (uint i = 0; i < inst.n; i++) { y[i] = EC.scalar_mul(EC.P2(), y0[i]); }

        GS.GSParams memory params = GS.buildParams(paramsRand);
        GS.GSCom memory com = GS.commit(inst,params,x,y,rst);
        GS.GSProof memory proof = GS.prove(inst,params,com,x,y,rst);

        return GS.verifyProof(inst, params, com, proof);
    }

    function dummyFunction(bool a) public view returns (bool) {
        return a;
    }
}
