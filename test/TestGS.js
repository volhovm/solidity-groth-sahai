const TestGS = artifacts.require("TestGS");

contract("TestGS", accounts => {
    it("dummy function should pass", () =>
        TestGS.deployed()
            .then(instance => instance.dummyFunction.call(true))
            .then(result => {
                assert.equal(
                    result.valueOf(),
                    true,
                    "Mda, dummy function tast has failed"
                );
            }));
    it("inverted dummy function should fail", () =>
        TestGS.deployed()
            .then(instance => instance.dummyFunction.call(false))
            .then(result => {
                assert.equal(
                    result.valueOf(),
                    false,
                    "Somehow dummy function succeeded"
                );
            }));

});
