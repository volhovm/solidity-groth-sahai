var LibBN256G2 = artifacts.require("BN256G2");
var LibEC = artifacts.require("EC");
var LibGS = artifacts.require("GS");
var TestGS = artifacts.require("TestGS");

module.exports = function(deployer) {
    deployer.deploy(LibBN256G2);
    deployer.link(LibBN256G2, [LibEC, LibGS, TestGS]);

    deployer.deploy(LibEC);
    deployer.link(LibEC, [LibGS, TestGS]);

    deployer.deploy(LibGS);
    deployer.link(LibGS, TestGS);

    deployer.deploy(TestGS);
};
