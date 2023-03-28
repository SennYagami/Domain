import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { DIDRegistrarControllerV1 } from "../typechain-types";
import { Wallet } from "ethers";
import { randomHex } from "../utils/encoding";
import hre from "hardhat";

import {
  generateMessageHash,
  generateWhitelistMessage,
  nonceGenerator,
} from "../utils/whitelistProcess";
import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import { faucet } from "../utils/faucet";

describe("Register controller test", async function () {
  const chainId = hre.network.config.chainId;

  let RegistrarController: DIDRegistrarControllerV1;

  const _registrar = ethers.constants.AddressZero;
  const _prices = ethers.constants.AddressZero;
  const _referralHub = ethers.constants.AddressZero;
  const _minCommitmentAge = 15;
  const _maxCommitmentAge = 86400;
  const resolverAddress = ethers.constants.AddressZero;

  const { provider } = ethers;
  const registrarControllerOwner: Wallet = new ethers.Wallet(randomHex(32), provider);
  const freeMinter: Wallet = new ethers.Wallet(randomHex(32), provider);

  console.log({
    registrarControllerOwner: registrarControllerOwner.address,
    freeMinter: freeMinter.address,
  });

  before(async () => {
    await faucet(registrarControllerOwner.address, provider);
    await faucet(freeMinter.address, provider);

    const RegistrarControllerFactory = await ethers.getContractFactory(
      "DIDRegistrarControllerV1",
      registrarControllerOwner
    );

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
    it("commit", async function () {});
    it("registerWithConfig", async function () {});
  });

  describe("free register", function () {
    it("free register ", async function () {
      const duration = 60 * 60 * 24 * 365;
      const secondaryNameLength = 2;

      // get nonce
      const nonce = await nonceGenerator(freeMinter.address, secondaryNameLength, duration);

      const { msgHash } = generateMessageHash(
        chainId,
        RegistrarController.address,
        freeMinter.address,
        "do",
        secondaryNameLength,
        nonce,
        duration
      );

      var compactSig = await registrarControllerOwner.signMessage(msgHash);
      //   compactSig =
      //     compactSig.slice(0, compactSig.length - 2) +
      //     (compactSig.slice(compactSig.length - 2, compactSig.length) == "1b" ? "1f" : "20");

      // construct free mint message
      const msg = generateWhitelistMessage(
        freeMinter.address,
        "do",
        secondaryNameLength,
        nonce,
        duration,
        compactSig
      );

      await RegistrarController.connect(freeMinter).whitelistRegister(
        msg,
        "do",
        ethers.constants.AddressZero
      );
    });
  });

  describe("renew", function () {
    it("", async function () {});
  });

  describe("rentPrice", function () {
    it("", async function () {});
  });

  describe("available", function () {
    it("", async function () {});
  });
});
