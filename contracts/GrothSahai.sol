pragma solidity >=0.4.22 <0.7.0;
pragma experimental ABIEncoderV2;

import "EC.sol";

// TODO So far I'm not using safemath. Maybe I should?

library GrothSahai {

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
        EC.G1Point u11;
        EC.G1Point u12;
        EC.G2Point u21;
        EC.G2Point u22;
    }

    struct GSProof {
        EC.G1Point proof11;
        EC.G1Point proof12;
        EC.G2Point proof21;
        EC.G2Point proof22;
    }

    struct GSCom {
        EC.G1Point[] com11;
        EC.G1Point[] com12;
        EC.G2Point[] com21;
        EC.G2Point[] com22;
    }

    function G1PointEq(EC.G1Point memory a, EC.G1Point memory b) private pure returns (bool) {
        return a.X == b.X && a.Y == b.Y;
    }

    function G2PointEq(EC.G2Point memory a, EC.G2Point memory b) private pure returns (bool) {
        return a.X[0] == b.X[0] && a.Y[0] == b.Y[0] &&
               a.X[1] == b.X[1] && a.Y[1] == b.Y[1];
    }

    // Compares u ~= [e], where u is a vector of group elements and e
    // is an example vector, consisting of field elements and bottoms.
    function alikeG1 (EC.G1Point[] memory u, int[] memory e) private returns (bool) {
        EC.G1Point memory g = EC.P1();
        for (uint i = 0; i < e.length; i++) {
            if (e[i] == -1 && !(G1PointEq(u[i], EC.scalar_mul(g, uint256(e[i])))))
                return false;
        }
        return true;
    }

    // FIXME Same as alikeG1, but for G2
    function alikeG2 (EC.G2Point[] memory u, int[] memory e) private returns (bool) {
        EC.G2Point memory g = EC.P2();
        for (uint i = 0; i < e.length; i++) {
            assert(false); // FIXME write/find scalar mult for G2?
        }
        return true;
    }


    function verifyEq(GSInstance memory inst,
                      GSParams memory params,
                      GSCom memory com,
                      GSProof memory proof
                      ) public returns (bool) {
        if (!alikeG1(com.com11, inst.a)) return false;
        if (!alikeG1(com.com12, inst.a)) return false;
        if (!alikeG2(com.com21, inst.b)) return false;
        if (!alikeG2(com.com22, inst.b)) return false;

        { /////// Pairing equation 1/4;
            EC.G1Point[] memory p1 = new EC.G1Point[](inst.m + 2);
            EC.G2Point[] memory p2 = new EC.G2Point[](inst.n + 2);

            for (uint i = 0; i < inst.n; i++) {
                for (uint j = 0; j < inst.m; j++) {
                    p1[i] = EC.scalar_mul(com.com11[j], inst.gammaT[i][j]);
                }
            }
            p1[inst.m] = params.u11;
            p1[inst.m+1] = proof.proof11;

            for (uint i = 0; i < inst.n; i++) { p2[i] = com.com21[i]; }
            p2[inst.n] = proof.proof21;
            p2[inst.n+1] = params.u21;

            if (!EC.pairing(p1,p2)) return false;
        }

        {
            /////// Pairing equation 2/4;
            EC.G1Point[] memory p1 = new EC.G1Point[](inst.m + 2);
            EC.G2Point[] memory p2 = new EC.G2Point[](inst.n + 2);

            for (uint i = 0; i < inst.n; i++) {
                for (uint j = 0; j < inst.m; j++) {
                    p1[i] = EC.scalar_mul(com.com12[j], inst.gammaT[i][j]);
                }
            }
            p1[inst.m] = params.u12;
            p1[inst.m+1] = proof.proof12;

            for (uint i = 0; i < inst.n; i++) { p2[i] = com.com21[i]; }
            p2[inst.n] = proof.proof21;
            p2[inst.n+1] = params.u21;

            if (!EC.pairing(p1,p2)) return false;
        }

        { /////// Pairing equation 3/4;
            EC.G1Point[] memory p1 = new EC.G1Point[](inst.m + 2);
            EC.G2Point[] memory p2 = new EC.G2Point[](inst.n + 2);

            for (uint i = 0; i < inst.n; i++) {
                for (uint j = 0; j < inst.m; j++) {
                    p1[i] = EC.scalar_mul(com.com11[j], inst.gammaT[i][j]);
                }
            }
            p1[inst.m] = params.u11;
            p1[inst.m+1] = proof.proof11;

            for (uint i = 0; i < inst.n; i++) { p2[i] = com.com22[i]; }
            p2[inst.n] = proof.proof22;
            p2[inst.n+1] = params.u22;

            if (!EC.pairing(p1,p2)) return false;
        }

        { /////// Pairing equation 4/4;
            EC.G1Point[] memory p1 = new EC.G1Point[](inst.m + 2);
            EC.G2Point[] memory p2 = new EC.G2Point[](inst.n + 2);

            for (uint i = 0; i < inst.n; i++) {
                for (uint j = 0; j < inst.m; j++) {
                    p1[i] = EC.scalar_mul(com.com12[j], inst.gammaT[i][j]);
                }
            }
            p1[inst.m] = params.u12;
            p1[inst.m+1] = proof.proof12;

            for (uint i = 0; i < inst.n; i++) { p2[i] = com.com22[i]; }
            p2[inst.n] = proof.proof22;
            p2[inst.n+1] = params.u22;

            if (!EC.pairing(p1,p2)) return false;
        }

        return true;
    }
}
