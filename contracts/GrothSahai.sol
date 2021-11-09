pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import "./EC.sol";

// TODO So far I'm not using safemath (explicitly?). Maybe I should?

library GS {

    struct V1Elem {
        EC.G1Point[2] v1;
    }

    struct V2Elem {
        EC.G2Point[2] v2;
    }

    struct GSInstance {
        uint m;
        uint n;

        // Must be transposed!
        int[][] gammaT;

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
        V1Elem[] com1; // C, of length m
        V2Elem[] com2; // D, of length n
    }

    struct GSProof {
        V1Elem[2] theta;
        V2Elem[2] phi;
    }


    // Compares u ~= [e], where u is a vector of group elements and e
    // is an example vector, consisting of field elements and bottoms.
    function comAlike (V1Elem[] memory u, int[] memory e) private view returns (bool) {
        for (uint i = 0; i < e.length; i++) {
            if (e[i] != -1 && (!(EC.pointEq(u[i].v1[0], EC.Z1())) ||
                               !(EC.pointEq(u[i].v1[1], EC.scalar_mul(EC.P1(), e[i])))))
                return false;
        }
        return true;
    }

    // Same as comAlike for G1, but for G2
    function comAlike (V2Elem[] memory u, int[] memory e) private view returns (bool) {
        for (uint i = 0; i < e.length; i++) {
            if (e[i] != -1 && (!(EC.pointEq(u[i].v2[0], EC.Z2())) ||
                               !(EC.pointEq(u[i].v2[1], EC.scalar_mul(EC.P2(), e[i])))))
                return false;
        }
        return true;
    }


    event EDebugMsg(string logmsg);


    function verifyProof(GSInstance memory inst,
                         GSParams memory params,
                         GSCom memory com,
                         GSProof memory proof
                        ) public returns (bool) {

        emit EDebugMsg("before coms");
        if (!comAlike(com.com1, inst.a)) return false;
        if (!comAlike(com.com2, inst.b)) return false;
        emit EDebugMsg("after coms");

        EC.G1Point[] memory p1 = new EC.G1Point[](inst.m + 4);
        EC.G2Point[] memory p2 = new EC.G2Point[](inst.m + 4);

        for (uint vv1 = 0; vv1 < 2; vv1++) {
            for (uint vv2 = 0; vv2 < 2; vv2++) {
                for (uint i = 0; i < inst.m; i++) {
                    p1[i] = com.com1[i].v1[vv1];
                    for (uint j = 0; j < inst.n; j++) {
                        p2[i] = EC.scalar_mul(com.com2[j].v2[vv2], inst.gammaT[j][i]);
                    }
                }
                for (uint i = 0; i < 2; i++) {
                    p1[inst.m+i] = EC.negate(params.u1[i].v1[vv1]);
                    p2[inst.m+i] = proof.phi[i].v2[vv2];
                }
                for (uint i = 0; i < 2; i++) {
                   p1[inst.m+2+i] = proof.theta[i].v1[vv1];
                   p2[inst.m+2+i] = EC.negate(params.u2[i].v2[vv2]);
                }
                // We don't need this because 'pairing' func adds 1 to the equation
                //if (vv1 == 1 && vv2 == 1) {
                //    // Something wrong here definitely.
                //    p1[inst.m+5] = EC.Z1();
                //    p2[inst.m+5] = EC.Z2();
                //} else {
                //    p1[inst.m+5] = EC.P1();
                //    p2[inst.m+5] = EC.P2();
                //}
                if (!EC.pairing(p1,p2)) return false;
                emit EDebugMsg("STEP ?/4");
            }
        }

        return true;
    }

    function buildParams(int[2][2][2] memory rand) public view returns (GSParams memory r) {
        // subspaces should not be in form (0,a)? This is from CKLM
        assert(!(rand[0][0][0] == 0 && rand[0][1][0] == 0 && rand[0][0][1] == rand[0][1][1]));
        assert(!(rand[1][0][0] == 0 && rand[1][1][0] == 0 && rand[1][0][1] == rand[1][1][1]));
        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2; j++) {
                r.u1[i].v1[j] = EC.scalar_mul(EC.P1(), rand[0][i][j]);
            }
        }
        for (uint i = 0; i < 2; i++) {
            for (uint j = 0; j < 2; j++) {
                r.u2[i].v2[j] = EC.scalar_mul(EC.P2(), rand[1][i][j]);
            }
        }
    }

    function commit(GSInstance memory inst,
                    GSParams memory params,
                    EC.G1Point[] memory x,
                    EC.G2Point[] memory y,
                    int[][][] memory rs // randomness; rs[0] is r, rs[1] is s
                    )
        public view returns (GSCom memory) {

        V1Elem[] memory com1 = new V1Elem[](inst.m);
        V2Elem[] memory com2 = new V2Elem[](inst.n);

        {EC.G1Point memory tmp;
        for (uint i = 0; i < inst.m; i++) {
            for (uint vv = 0; vv < 2; vv++) {
                com1[i].v1[vv] =
                    EC.addition(EC.scalar_mul(params.u1[0].v1[vv], rs[0][i][0]),
                                EC.scalar_mul(params.u1[1].v1[vv], rs[0][i][1]));
            }
            com1[i].v1[1] = EC.addition(com1[i].v1[1], x[i]);
        }}

        {EC.G2Point memory tmp;
        for (uint i = 0; i < inst.n; i++) {
            for (uint vv = 0; vv < 2; vv++) {
                com2[i].v2[vv] =
                    EC.addition(EC.scalar_mul(params.u2[0].v2[vv], rs[1][i][0]),
                                EC.scalar_mul(params.u2[1].v2[vv], rs[1][i][1]));
            }
            com2[i].v2[1] = EC.addition(com2[i].v2[1], y[i]);
        }}

        return GSCom(com1,com2);
    }

    event EDebug1(string logmsg, EC.G2Point points);

    function prove(GSInstance memory inst,
                   GSParams memory params,
                   GSCom memory com,
                   EC.G1Point[] memory x,
                   EC.G2Point[] memory y,
                   int[][][] memory rst // randomness; rst[0] is r, rst[1] is s, rst[2] is t
                   )
        public returns (GSProof memory res) {

        // theta, v1[0] and v1[1]
        for (uint i = 0; i < 2; i++) {
            // T U_1
            for (uint vv = 0; vv < 2; vv++) {
                res.theta[i].v1[vv] = EC.Z1();
                for (uint j = 0; j < 2; j++) {
                    res.theta[i].v1[vv] =
                        EC.addition(res.theta[i].v1[vv],
                                    EC.scalar_mul(params.u1[j].v1[vv], rst[2][i][j]));
                }
            }
            // s^T \Gamma^T \iota_1(X), only for vv = 1 because of \iota_1(X)
            for (uint j = 0; j < inst.n; j++) {
                for (uint k = 0; k < inst.m; k++) {
                    res.theta[i].v1[1] =
                        EC.addition(res.theta[i].v1[1],
                                    EC.scalar_mul(EC.scalar_mul(x[k], inst.gammaT[j][k]),
                                                  rst[1][j][i]));
                }
            }
        }



        // phi, v2[0] and v2[1]
        for (uint vv = 0; vv < 2; vv++) {
            for (uint i = 0; i < 2; i++) {
                res.phi[i].v2[vv] = EC.Z2();
                // r^T \Gamma D
                for (uint j = 0; j < inst.m; j++) {
                    for (uint k = 0; k < inst.n; k++) {
                        res.phi[i].v2[vv] =
                            EC.addition(res.phi[i].v2[vv],
                                        EC.scalar_mul(EC.scalar_mul(com.com2[k].v2[vv],inst.gammaT[k][j]),rst[0][j][i]));
                    }
                }
                // -T^T U_2
                EC.G2Point memory tmp;
                for (uint j = 0; j < 2; j++) {
                    res.phi[i].v2[vv] = EC.addition(res.phi[i].v2[vv], EC.negate(EC.scalar_mul(params.u2[j].v2[vv], rst[2][j][i])));
                    //emit EDebug1("prove", tmp);
                }
            }
        }

    }

}
