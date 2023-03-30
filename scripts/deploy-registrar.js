const hre = require("hardhat");
const {expect} = require("chai");
const config = require("./deploy-config.json");

async function main() {
    const ENS = config.registrar.ENS;

    const [owner, userAddr] = await hre.ethers.getSigners();
    console.log("owner adress:", owner.address)
    const Registrar = await hre.ethers.getContractFactory("Registrar");
    const registrar0 = await hre.upgrades.deployProxy(Registrar, {kind: 'uups'})
    await registrar0.deployed();
    const registrar = await hre.ethers.getContractAt("Registrar", registrar0.address)
    await registrar.initializeRegistrar(ENS);

    expect(owner.address == registrar.owner());

    console.log("Registrar address:", registrar.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
