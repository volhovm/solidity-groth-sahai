const TestGS = artifacts.require("TestGS");

contract("TestGS", accounts => {


    it("dummy function should pass", () =>
        TestGS.deployed()
            .then(instance => instance.dummyFunction.call(true))
            .then(result => {
                assert.equal( result.valueOf(), true, "Mda, dummy function tast has failed");
            }));
    it("inverted dummy function should fail", () =>
        TestGS.deployed()
            .then(instance => instance.dummyFunction.call(false))
            .then(result =>
                assert.equal(result.valueOf(), false, "Somehow dummy function succeeded")
            ));

    it("passStructSample positive", () => {
        return TestGS.deployed()
            .then(instance => instance.passStructSample.call({x:1, y:2}))
            .then(result => {
                assert.equal(result.valueOf(), true, "Struct was passed incorrectly");
            });});

    it("passStructSample negative", () => {
        return TestGS.deployed()
            .then(instance => instance.passStructSample.call({x:0, y:2}))
            .then(result => {
                assert.equal(result.valueOf(), false, "Struct was passed incorrectly");
            });});

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



    it("negation in G1/G2 works", async () => {
        const instance = await TestGS.deployed();
        const result = await instance.testNegate.call();
        const receipt = await instance.testNegate();
        console.log(receipt.logs);


        assert.equal(result.valueOf(), true, "The result was not true");
    });

//    // witness X Y
//    // Equation: e(X1,H)e(G,-Y2) = 1
//    // X2 = 1, Y1 = 1, so A = (-1,1), B = (1,-1)
//    // Gamma =
//    //  (1  0)
//    //  (0 -1)
//    // Basically the witness inside X1 should be the
//    it("verifyProofSample returns true", () => {
//        let gsInst = { m: 2, n: 2, gammaT: [[1,0],[0,-1]], a: [-1,1], b: [1,-1] };
//        let x = [123, 1];
//        let y = [1, 123];
//        // Zeroes in commitments here correspond to non-(-1) values in a and b
//        let rst = [ [[1235,3462],[0,0]],
//                    [[0,0],[1924,6258]],
//                    [[8334,1953],[2342,4935]]
//                  ];
//        let paramsR = [[[64321,83371],[12924,62558]],
//                       [[83334,19553],[25342,43935]]];
//        return TestGS.deployed()
//            .then(instance => instance.verifyProof1.call(gsInst,x,y,rst,paramsR))
//            .then(result =>  assert.equal(result.valueOf(), true, "Proof verification failed"));
//    });

});
