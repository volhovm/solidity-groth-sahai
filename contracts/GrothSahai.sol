pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import "./EC.sol";

// TODO So far I'm not using safemath. Maybe I should?

library GrothSahai {


    function pointEq(EC.G1Point memory a, EC.G1Point memory b) private pure returns (bool) {
        return a.X == b.X && a.Y == b.Y;
    }

    function pointEq(EC.G2Point memory a, EC.G2Point memory b) private pure returns (bool) {
        return a.X[0] == b.X[0] && a.Y[0] == b.Y[0] &&
               a.X[1] == b.X[1] && a.Y[1] == b.Y[1];
    }


    function vecAdd(EC.G1Point[] memory a, EC.G1Point[] memory b)
        private view returns (EC.G1Point[] memory) {
        EC.G1Point[] memory res = new EC.G1Point[](a.length);
        for (uint i = 0; i < a.length; i++) { res[i] = EC.addition(a[i],b[i]); }
        return res;
    }

    function vecAdd(EC.G2Point[] memory a, EC.G2Point[] memory b)
        private view returns (EC.G2Point[] memory) {
        EC.G2Point[] memory res = new EC.G2Point[](a.length);
        for (uint i = 0; i < a.length; i++) { res[i] = EC.addition(a[i],b[i]); }
        return res;
    }

    struct V1Elem {
        EC.G1Point v11;
        EC.G1Point v12;
    }

    struct V2Elem {
        EC.G2Point v21;
        EC.G2Point v22;
    }

    function addV(V1Elem memory e1, V1Elem memory e2) private view returns (V1Elem memory e3) {
        e3.v11 = EC.addition(e1.v11, e2.v11);
        e3.v12 = EC.addition(e1.v12, e2.v12);
    }

    function addV(V2Elem memory e1, V2Elem memory e2) private view returns (V2Elem memory e3) {
        e3.v21 = EC.addition(e1.v21, e2.v21);
        e3.v22 = EC.addition(e1.v22, e2.v22);
    }


    struct GSInstance {
        uint m;
        uint n;

        // Must be transposed!
        uint[][] gammaT;

        // -1 in these is interpreted as "no value"
        int[] a;
        int[] b;
    }

    // This must be pre-negated already, as compared to the description in CKLM
    struct GSParams {
        V1Elem[2] u1; // u1[i] is a two-vector from V1
        V2Elem[2] u2;
    }

    struct GSCom {
        V1Elem[] com1; // C
        V2Elem[] com2; // D
    }

    struct GSProof {
        V1Elem[2] theta;
        V2Elem[2] phi;
    }


    // Compares u ~= [e], where u is a vector of group elements and e
    // is an example vector, consisting of field elements and bottoms.
    function vecAlike (EC.G1Point[] memory u, int[] memory e) private view returns (bool) {
        EC.G1Point memory g = EC.P1();
        for (uint i = 0; i < e.length; i++) {
            if (e[i] == -1 && !(pointEq(u[i], EC.scalar_mul(g, uint256(e[i])))))
                return false;
        }
        return true;
    }

    // Same as vecAlike for G1, but for G2
    function vecAlike (EC.G2Point[] memory u, int[] memory e) private view returns (bool) {
        EC.G2Point memory g = EC.P2();
        for (uint i = 0; i < e.length; i++) {
            if (e[i] == -1 && !(pointEq(u[i], EC.scalar_mul(g, uint256(e[i])))))
                return false;
        }
        return true;
    }

    function verifyEqRaw(GSInstance memory inst,
                         EC.G1Point[] memory com1,
                         EC.G1Point memory u1,
                         EC.G1Point memory proof1,
                         EC.G2Point[] memory com2,
                         EC.G2Point memory u2,
                         EC.G2Point memory proof2
                         ) public view returns (bool) {
        EC.G1Point[] memory p1 = new EC.G1Point[](inst.m + 2);
        EC.G2Point[] memory p2 = new EC.G2Point[](inst.n + 2);

        for (uint i = 0; i < inst.n; i++) {
            for (uint j = 0; j < inst.m; j++) {
                p1[i] = EC.scalar_mul(com1[j], inst.gammaT[i][j]);
            }
        }
        p1[inst.m] = u1;
        p1[inst.m+1] = proof1;

        for (uint i = 0; i < inst.n; i++) { p2[i] = com2[i]; }
        p2[inst.n] = proof2;
        p2[inst.n+1] = u2;

        return EC.pairing(p1,p2);
    }


    //    function verifyProof(GSInstance memory inst,
    //                      GSParams memory params,
    //                      GSCom memory com,
    //                      GSProof memory proof
    //                      ) public view returns (bool) {
    //        if (!vecAlike(com.com11, inst.a)) return false;
    //        if (!vecAlike(com.com12, inst.a)) return false;
    //        if (!vecAlike(com.com21, inst.b)) return false;
    //        if (!vecAlike(com.com22, inst.b)) return false;
    //
    //        //        if (!verifyEqRaw(inst, com.com11, params.u11, proof.proof11,
    //        //                         com.com21, params.u21, proof.proof21)) return false;
    //        //        if (!verifyEqRaw(inst, com.com12, params.u12, proof.proof12,
    //        //                         com.com21, params.u21, proof.proof21)) return false;
    //        //        if (!verifyEqRaw(inst, com.com11, params.u11, proof.proof11,
    //        //                         com.com22, params.u22, proof.proof22)) return false;
    //        //        if (!verifyEqRaw(inst, com.com12, params.u12, proof.proof12,
    //        //                         com.com22, params.u22, proof.proof22)) return false;
    //
    //        return true;
    //    }

    function commit(GSInstance memory inst,
                    GSParams memory params,
                    EC.G1Point[] memory x,
                    EC.G2Point[] memory y,
                    uint[][][] memory rs // randomness; rs[0] is r, rs[1] is s
                    )
        public view returns (GSCom memory) {

        V1Elem[] memory com1 = new V1Elem[](x.length);
        V2Elem[] memory com2 = new V2Elem[](y.length);

        {EC.G1Point memory tmp;
        for (uint i = 0; i < x.length; i++) {
            tmp = EC.addition(EC.scalar_mul (params.u1[0].v11, rs[0][i][0]),
                              EC.scalar_mul (params.u1[1].v11, rs[0][i][1]));
            com1[i].v11 = EC.addition(x[i], tmp);
            tmp = EC.addition(EC.scalar_mul (params.u1[0].v12, rs[0][i][0]),
                              EC.scalar_mul (params.u1[1].v12, rs[0][i][1]));
            com1[i].v12 = EC.addition(x[i], tmp);
        }}

        {EC.G2Point memory tmp;
        for (uint i = 0; i < y.length; i++) {
            tmp = EC.addition(EC.scalar_mul (params.u2[0].v21, rs[1][i][0]),
                              EC.scalar_mul (params.u2[1].v21, rs[1][i][1]));
            com2[i].v21 = EC.addition(y[i], tmp);
            tmp = EC.addition(EC.scalar_mul (params.u2[0].v22, rs[1][i][0]),
                              EC.scalar_mul (params.u2[1].v22, rs[1][i][1]));
            com2[i].v22 = EC.addition(y[i], tmp);
        }}


        return GSCom(com1,com2);
    }


    function prove(GSInstance memory inst,
                   GSParams memory params,
                   GSCom memory com,
                   EC.G1Point[] memory x,
                   EC.G2Point[] memory y,
                   uint[][][] memory rst // randomness; rst[0] is r, rst[1] is s, rst[2] is t
                   )
        public view returns (GSProof memory res) {

        // theta, v11
        for (uint i = 0; i < 2; i++) {
            res.theta[i].v11 = EC.P1();
            for (uint j = 0; j < y.length; j++) {
                for (uint k = 0; k < x.length; k++) {
                    res.theta[i].v11 =
                        EC.addition(res.theta[i].v11,
                                    EC.scalar_mul(EC.scalar_mul(x[k], inst.gammaT[j][k]),
                                                  rst[1][j][0]));
                }
            }
            for (uint j = 0; j < 2; j++) {
                res.theta[i].v11 =
                    EC.addition(res.theta[i].v11,
                                EC.scalar_mul(params.u1[j].v11, rst[2][i][j]));
            }
        }

        // theta, v12
        for (uint i = 0; i < 2; i++) {
            res.theta[i].v12 = EC.P1();
            // this first loop is the same as for theta v11
            for (uint j = 0; j < y.length; j++) {
                for (uint k = 0; k < x.length; k++) {
                    res.theta[i].v12 =
                        EC.addition(res.theta[i].v12,
                                    EC.scalar_mul(EC.scalar_mul(x[k], inst.gammaT[j][k]),
                                                  rst[1][j][0]));
                }
            }
            // but this one is different, uses u1[j].v12
            for (uint j = 0; j < 2; j++) {
                res.theta[i].v12 =
                    EC.addition(res.theta[i].v12,
                                EC.scalar_mul(params.u1[j].v12, rst[2][i][j]));
            }
        }

        for (uint i = 0; i < 2; i++) {
            res.phi[i].v21 = EC.P2();
            for (uint j = 0; j < x.length; j++) {
                for (uint k = 0; k < y.length; k++) {
                    res.phi[i].v21 =
                        EC.addition(res.phi[i].v21,
                                    EC.scalar_mul(EC.scalar_mul(com.com2[k].v21,inst.gammaT[k][j]),rst[0][j][i]));
                }
            }
            for (uint j = 0; j < 2; j++) {
                for (uint k = 0; k < y.length; k++) {
                    res.phi[i].v21 =
                        EC.subtract(res.phi[i].v21,
                                    EC.scalar_mul(params.u2[j].v21, rst[2][j][i]));
                }
            }
        }

    }


}
