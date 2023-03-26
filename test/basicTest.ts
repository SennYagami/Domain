import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BNBRegistrarControllerV9 } from "../typechain-types";
import { Wallet } from "ethers";
import { randomHex } from "../utils/encoding";

describe("Basic test", function () {
  let RegistrarController: BNBRegistrarControllerV9;

  const _registrar = ethers.constants.AddressZero;
  const _prices = ethers.constants.AddressZero;
  const _referralHub = ethers.constants.AddressZero;
  const _minCommitmentAge = 15;
  const _maxCommitmentAge = 86400;
  const resolverAddress = ethers.constants.AddressZero;

  const { provider } = ethers;
  const registrarControllerOwner: Wallet = new ethers.Wallet(randomHex(32), provider);

  this.beforeAll(async () => {
    const RegistrarControllerFactory = await ethers.getContractFactory("BNBRegistrarControllerV9");
    RegistrarController = await RegistrarControllerFactory.deploy(
      _registrar,
      _prices,
      _referralHub,
      _minCommitmentAge,
      _maxCommitmentAge,
      resolverAddress
    );
  });

  describe("register", function () {
    it("Should commitment equals", async function () {});
  });
});
