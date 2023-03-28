const { expect } = require("chai");
const hre = require("hardhat");
const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("TEST", function () {
  const RegistrarEventHash = {
    ControllerAdded: "0x0a8bb31534c0ed46f380cb867bd5c803a189ced9a764e30b3a4991a9901d7474",
    ControllerRemoved: "0x33d83959be2573f5453b12eb9d43b3499bc57d96bd2f067ba44803c859e81113",
    NameRegistered: "0x3b0bee99c00308f93ddbdda596f2aebcc9ad1595670808407e7ca83910a744b5",
    NameRenewed: "0xfa04f489269baee5d1fe3c9cf3f776ee0e11397ebd0fe7db62442138bf46b09f",
    OwnershipTransferred: "0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0",
  };

  async function deployMockRegistry() {
    const MockRegistry = await hre.ethers.getContractFactory("MockRegistry");
    const mockRegistry = await MockRegistry.deploy();
    await mockRegistry.deployed();

    return mockRegistry;
  }

  async function deployRegistrar(ENS) {
    const [owner, userAddr] = await hre.ethers.getSigners();
    const Registrar = await hre.ethers.getContractFactory("Registrar");
    const registrar = await Registrar.deploy(ENS);
    await registrar.deployed();
    expect(owner.address == registrar.owner());

    return { registrar, owner, userAddr };
  }

  async function _parseTransEvent(trans, eventHash, contractInstance) {
    let transReceipt = await hre.ethers.provider.getTransactionReceipt(trans.hash);
    let event;
    let eventAbi;
    for (let i = 0; i < transReceipt.logs.length; i++) {
      event = transReceipt.logs[i];
      if (event.address != contractInstance.address) {
        continue;
      }
      if (event.topics[0] != eventHash) {
        continue;
      }

      switch (eventHash) {
        case RegistrarEventHash.ControllerAdded:
          eventAbi = ["event ControllerAdded(address indexed controller)"];
          break;
        case RegistrarEventHash.ControllerRemoved:
          eventAbi = ["event ControllerRemoved(address indexed controller)"];
          break;
        case RegistrarEventHash.NameRegistered:
          eventAbi = [
            "event NameRegistered(string rootDomainName, string secondaryDomainName, address indexed owner, uint256 expires)",
          ];
          break;
        case RegistrarEventHash.NameRenewed:
          eventAbi = [
            "event NameRenewed(string rootDomainName, string secondaryDomainName, uint256 expires)",
          ];
          break;
      }

      if (event != null) {
        break;
      }
    }

    if (eventAbi == null) {
      throw "no matched eventHash";
    }

    let iface = new hre.ethers.utils.Interface(eventAbi);
    let log = iface.parseLog(event); // here you can add your own logic to find the correct log

    return log.args;
  }

  describe("Registrar-test", function () {
    it("addController", async function () {
      let ENS = await deployMockRegistry();
      let { registrar, owner, userAddr } = await deployRegistrar(ENS.address);

      let trans = await registrar.addController(userAddr.address);
    });
    it("removeController", async function () {
      let ENS = await deployMockRegistry();
      let { registrar, owner, userAddr } = await deployRegistrar(ENS.address);

      await registrar.addController(userAddr.address);
      let trans = await registrar.removeController(userAddr.address);
    });
    it("NameRegistered", async function () {
      let ENS = await deployMockRegistry();
      let { registrar, owner, userAddr } = await deployRegistrar(ENS.address);
      await registrar.addController(owner.address);

      let duration = 10 * 60; //seconds
      let rootDomain = "hello.do";
      let secondaryDomain = "cc.hello";
      let trans = await registrar.register(rootDomain, secondaryDomain, userAddr.address, duration);
      {
        let logargs = await _parseTransEvent(trans, RegistrarEventHash.NameRegistered, registrar);
        expect(logargs[0]).to.equal(rootDomain);
        expect(logargs[1]).to.equal(secondaryDomain);
        expect(logargs[2]).to.equal(userAddr.address);
        expect(logargs[3]).to.equal((await time.latest()) + duration);
      }
    });
    it("renew", async function () {
      let ENS = await deployMockRegistry();
      let { registrar, owner, userAddr } = await deployRegistrar(ENS.address);
      await registrar.addController(owner.address);

      let duration = 20 * 60; //seconds
      let rootDomain = "hello.do";
      let secondaryDomain = "cc.hello";
      await registrar.register(rootDomain, secondaryDomain, userAddr.address, duration);

      let trans = await registrar.renew(rootDomain, secondaryDomain, duration);
      {
        let cur = (await time.latest()) + duration;
        let logargs = await _parseTransEvent(trans, RegistrarEventHash.NameRenewed, registrar);
        expect(logargs[0]).to.equal(rootDomain);
        expect(logargs[1]).to.equal(secondaryDomain);
        expect(logargs[2]).to.greaterThan(cur);
      }
    });
    it("Exception", async function () {});
  });
});
