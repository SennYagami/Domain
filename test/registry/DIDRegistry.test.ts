import { ethers, upgrades } from "hardhat";
import { expect } from "chai";
import { DIDRegistry } from "../../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("TestRegistry", function () {
    let contract: DIDRegistry;
    let account0: SignerWithAddress;
    let account1: SignerWithAddress;
    let addres0: string;
    let addres1: string;

    beforeEach(async () => {
        let instance = await ethers.getContractFactory("DIDRegistry");
        const upgradeableContract = await upgrades.deployProxy(instance, [], { initializer: 'initialize' });
        await upgradeableContract.deployed();
        contract = upgradeableContract as DIDRegistry;
        [account0, account1] = await ethers.getSigners();
        addres0 = await account0.getAddress();
        addres1 = await account1.getAddress();
    });

    it("checkRootDomainValidity should return false for the did", async function () {
        const value = await contract.checkRootDomainValidity("did");
        expect(value).to.equal(false);
    });

    it("checkRootDomainValidity should return true for the jay", async function () {
        const value = await contract.checkRootDomainValidity("jay");
        expect(value).to.equal(true);
    });

    it("SubRootDomainCreator should equal to keccake('did')", async function () {
        const value = await contract.getSubRootDomainCreator("did");
        expect(value).to.equal(ethers.utils.keccak256(ethers.utils.toUtf8Bytes("did")));
    });

    it("setOwner should be wrong if not OwnerController", async function () {
        const node = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("jay"))
        await expect(contract.connect(account1).setOwner(node, addres1)).to.be.revertedWithoutReason();
    })

    it("setOwner should be ok", async function () {
        await contract.addOwnerController(addres1);
        const node = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("jay"))
        await contract.connect(account1).setOwner(node, addres1);
        const value = await contract.getOwner(node);
        expect(value).to.equal(addres1);
        await expect(contract.connect(account1).setOwner(node, addres1)).to.emit(contract, "Transfer").withArgs(node, addres1);
    })

    it("addOwnerController should be wrong if not owner", async function () {
        await expect(contract.connect(account1).addOwnerController(addres1)).to.be.revertedWith("Ownable: caller is not the owner");
    })

    it("addOwnerController should be ok", async function () {
        await contract.addOwnerController(addres1);
        const value = await contract.ownerControllers(addres1);
        expect(value).to.equal(true);
        await expect(contract.addOwnerController(addres1)).to.emit(contract, "OwnerControllerAdded").withArgs(addres1);
    })

    it("removeOwnerController should be wrong if not owner", async function () {
        await expect(contract.connect(account1).removeOwnerController(addres1)).to.be.revertedWith("Ownable: caller is not the owner");
    })

    it("removeOwnerController should be ok", async function () {
        await contract.addOwnerController(addres1);
        await contract.removeOwnerController(addres1);
        const value = await contract.ownerControllers(addres1);
        expect(value).to.equal(false);
        await expect(contract.removeOwnerController(addres1)).to.emit(contract, "OwnerControllerRemoved").withArgs(addres1);
    })

    it("addCreatorController should be wrong if not owner", async function () {
        await expect(contract.connect(account1).addCreatorController(addres1)).to.be.revertedWith("Ownable: caller is not the owner");
    })

    it("addCreatorController should be ok", async function () {
        await contract.addCreatorController(addres1);
        const value = await contract.creatorControllers(addres1);
        expect(value).to.equal(true);
        await expect(contract.addCreatorController(addres1)).to.emit(contract, "CreatorControllerAdded").withArgs(addres1);
    })

    it("removeCreatorController should be wrong if not owner", async function () {
        await expect(contract.connect(account1).removeCreatorController(addres1)).to.be.revertedWith("Ownable: caller is not the owner");
    })

    it("removeCreatorController should be ok", async function () {
        await contract.addCreatorController(addres1);
        await contract.removeCreatorController(addres1);
        const value = await contract.creatorControllers(addres1);
        expect(value).to.equal(false);
        await expect(contract.removeCreatorController(addres1)).to.emit(contract, "CreatorControllerRemoved").withArgs(addres1);
    })

    it("setSubRootDomainCreator should be wrong if not owner", async function () {
        const node = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("did"))
        await expect(contract.connect(account1).setSubRootDomainCreator("jay", node)).to.be.revertedWithoutReason();
    })

    it("setSubRootDomainCreator should be ok", async function () {
        await contract.addCreatorController(addres0);
        const node = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("did"))
        await contract.setSubRootDomainCreator("jay", node);
        const value = await contract.getSubRootDomainCreator("jay");
        expect(value).to.equal(node);
        const isValid = await contract.checkRootDomainValidity("jay");
        expect(isValid).to.equal(false);
        await expect(contract.setSubRootDomainCreator("jay", node)).to.emit(contract, "NewSubRootDomainCreator").withArgs(node, "jay");
    })

    it("setRegistry should be wrong if not creatorController", async function () {
        await expect(contract.connect(account1).setResolver(addres1)).to.be.revertedWith("Ownable: caller is not the owner");
    })

    it("setRegistry should be ok", async function () {
        await contract.setResolver(addres1);
        const value = await contract.resolver();
        expect(value).to.equal(addres1);
        await expect(contract.setResolver(addres1)).to.emit(contract, "NewResolver").withArgs(addres1);
    })
});