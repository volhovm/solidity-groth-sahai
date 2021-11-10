const TestGS = artifacts.require("TestGS");

contract("TestGS", accounts => {


//    it("dummy function should pass", () =>
//        TestGS.deployed()
//            .then(instance => instance.dummyFunction.call(true))
//            .then(result => {
//                assert.equal( result.valueOf(), true, "Mda, dummy function tast has failed");
//            }));
//    it("inverted dummy function should fail", () =>
//        TestGS.deployed()
//            .then(instance => instance.dummyFunction.call(false))
//            .then(result =>
//                assert.equal(result.valueOf(), false, "Somehow dummy function succeeded")
//            ));
//
//    it("passStructSample positive", () => {
//        return TestGS.deployed()
//            .then(instance => instance.passStructSample.call({x:1, y:2}))
//            .then(result => {
//                assert.equal(result.valueOf(), true, "Struct was passed incorrectly");
//            });});
//
//    it("passStructSample negative", () => {
//        return TestGS.deployed()
//            .then(instance => instance.passStructSample.call({x:0, y:2}))
//            .then(result => {
//                assert.equal(result.valueOf(), false, "Struct was passed incorrectly");
//            });});

//    it("passStructSample async", () => {
//        let meta;
//        let r0;
//
//        return TestGS.deployed()
//            .then(instance => {
//                meta = instance;
//                return instance.passStructSample.call({x:0, y:2});
//            })
//            .then(result0 => {
//                r0 = result0;
//                return meta.passStructSample.call({x:1, y:2})
//            })
//            .then(result1 => {
////                assert.equal(true,false,"Synthetic Abort");
//                assert.equal(r0.valueOf(),!result1.valueOf(),"how to use async?");
//                assert.equal(result1.valueOf(), true, "Struct was passed incorrectly");
//            });
//    });



//    it("negation in G1/G2 works", async () => {
//        const instance = await TestGS.deployed();
//        const result = await instance.testNegate.call();
//        const receipt = await instance.testNegate();
//        console.log(receipt.logs);
//
//        assert.equal(result.valueOf(), true, "The result was not true");
//    });

    it("P2 / zero bug", async () => {
        const instance = await TestGS.deployed();
        const result = await instance.testP2ZeroBug.call();
        const receipt = await instance.testP2ZeroBug();
        console.log(receipt.logs);

        assert.equal(result.valueOf(), true, "False can't be returned: true or segfault");
    });


//    // witness X Y
//    // Equation: e(X1,H)e(G,-Y2) = 1
//    // X2 = 1, Y1 = 1, so A = (-1,1), B = (1,-1)
//    //
//    // Gamma =
//    //  (1  0)
//    //  (0 -1)
//    //
//    // And any correct witness is X = (a,1), Y = (1,a), where a is any group element.
//    it("verifyProofSample returns true, basic lang", async () => {
//        let gsInst = { m: 2, n: 2, gammaT: [[1,0],[0,-1]], a: [-1,0], b: [0,-1] };
//        // these k correspond to [k]G, so 0 is group element 1: EC.P1() or EC.P2()
//        let x = [123, 0];
//        let y = [0, 123];
//        // Zeroes in commitments here correspond to fixed, non-(-1) values in a and b
//        // If we randomize these values inside commitmenst, we can't execute ~= check.
//        let rst = [ [[1235,3462],[0,0]],
//                    [[0,0],[1924,6258]],
//                    [[8334,1953],[2342,4935]]
//                  ];
//
//        let paramsR = [[[64321,83371],[12924,62558]],
//                       [[83334,19553],[25342,43935]]];
//
//
//        const instance = await TestGS.deployed();
//        const result = await instance.verifyProof1.call(gsInst,x,y,rst,paramsR);
//
//        // Showing events
//        const receipt = await instance.verifyProof1(gsInst,x,y,rst,paramsR);
//        console.log(receipt.logs);
//
//        assert.equal(result.valueOf(), true, "Proof verification failed");
//    });

    it("verifyProofSample returns true (GS E2)", async () => {
        let m = 100;
        let r = 823144;
        let sk = 214123;
        let ct = sk * r + m;
        let gsInst = { m: 3, n: 3, gammaT: [[1,0,0],[0,-1,0],[0,0,-1]]
                       , a: [ct,sk,-1], b: [0,-1, 0] };
        let x = [ct,sk,m];
        let y = [0,r,0];
        let rst = [ [[0,0],[0,0],[1235,3462]],
                    [[0,0],[1924,6258],[0,0]],
                    [[8334,1953],[2342,4935]]
                  ];

        let paramsR = [[[64321,83371],[12924,62558]],
                       [[83334,19553],[25342,43935]]];


        const instance = await TestGS.deployed();
        const result = await instance.verifyProof1.call(gsInst,x,y,rst,paramsR);

        // Showing events
        const receipt = await instance.verifyProof1(gsInst,x,y,rst,paramsR);
        console.log(receipt.logs);

        assert.equal(result.valueOf(), true, "Proof verification failed");
    });


});
