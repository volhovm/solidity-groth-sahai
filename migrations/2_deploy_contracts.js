var LibBN256G2 = artifacts.require("BN256G2");
var LibEC = artifacts.require("EC");
var LibGrothSahai = artifacts.require("GrothSahai");
var TestGS = artifacts.require("TestGS");

module.exports = function(deployer) {
    deployer.deploy(LibBN256G2);
    deployer.link(LibBN256G2, [LibEC, LibGrothSahai]);

    deployer.deploy(LibEC);
    deployer.link(LibEC, LibGrothSahai);

    deployer.deploy(LibGrothSahai);
    deployer.link(LibGrothSahai, TestGS);

    deployer.deploy(TestGS);
};
