import { ethers, upgrades } from "hardhat";
import { DIDRegistry } from "../../typechain-types";

async function DeployDIDRegistry(): Promise<DIDRegistry> {
    let instance = await ethers.getContractFactory("DIDRegistry");
    const upgradeableContract = await upgrades.deployProxy(instance, [], { initializer: 'initialize' });
    await upgradeableContract.deployed();
    return upgradeableContract as DIDRegistry;
}