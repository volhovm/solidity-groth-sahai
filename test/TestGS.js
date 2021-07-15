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

    it("passStructSample async", () => {
        let meta;
        let r0;

        return TestGS.deployed()
            .then(instance => {
                meta = instance;
                return instance.passStructSample.call({x:0, y:2});
            })
            .then(result0 => {
                r0 = result0;
                return meta.passStructSample.call({x:1, y:2})
            })
            .then(result1 => {
//                assert.equal(true,false,"Synthetic Abort");
                assert.equal(r0.valueOf(),!result1.valueOf(),"how to use async?");
                assert.equal(result1.valueOf(), true, "Struct was passed incorrectly");
            });
    });


//    it("verifyProofSample parses args correctly", () => {
//        let gsInst = { m: 2, n: 2, gammaT: [[1,2],[3,4]], a: [-1,1], b: [1,1] };
//        let gsParams = {};
//        let gsCom = {};
//        let gsProof = {};
//        TestGS.deployed()
//            .then(instance => instance.verifyProof.call(gsInst,gsParams,gsCom,gsProof))
//            .then(result => assert.equal(result.valueOf(), true, "Sample proof verifies correctly"));
//    });

});
