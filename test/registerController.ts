import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { DIDRegistrarControllerV1 } from "../typechain-types";
import { Wallet } from "ethers";
import { randomHex } from "../utils/encoding";
import hre from "hardhat";
import crypto from "crypto";

import {
  generateMessageHash,
  generateWhitelistMessage,
  nonceGenerator,
} from "../utils/whitelistProcess";
import { keccak256, toUtf8Bytes } from "ethers/lib/utils";
import { faucet } from "../utils/faucet";
import { zeroBytes32 } from "../utils/constants";

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
  const register_1: Wallet = new ethers.Wallet(randomHex(32), provider);

  //   console.log({
  //     registrarControllerOwner: registrarControllerOwner.address,
  //     freeMinter: freeMinter.address,
  //   });

  before(async () => {
    await faucet(registrarControllerOwner.address, provider);
    await faucet(freeMinter.address, provider);
    await faucet(register_1.address, provider);

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
    it("commit", async function () {
      // generate commitment
      const secret = "0x" + crypto.randomBytes(32).toString("hex");
      const commitment = await RegistrarController.makeCommitmentWithConfig(
        "do",
        "hello",
        register_1.address,
        secret,
        register_1.address
      );
      await RegistrarController.commit(commitment);

      await expect(await RegistrarController.commitments(commitment)).to.not.equal(0);
    });

    it("commit and register", async function () {
      // generate commitment
      const secret = "0x" + crypto.randomBytes(32).toString("hex");
      const commitment = await RegistrarController.makeCommitment(
        "do",
        "hello_1",
        register_1.address,
        secret
      );

      await RegistrarController.commit(commitment);

      await new Promise((r) => setTimeout(r, 15001));

      await RegistrarController.register("do", "hello_1", register_1.address, 86400 * 365, secret);
    });

    it("commit and registerWithConfig", async function () {
      // generate commitment
      const secret = "0x" + crypto.randomBytes(32).toString("hex");
      const commitment = await RegistrarController.makeCommitmentWithConfig(
        "do",
        "hello_2",
        register_1.address,
        secret,
        register_1.address
      );

      await RegistrarController.commit(commitment);

      await new Promise((r) => setTimeout(r, 15001));

      await RegistrarController.registerWithConfig(
        "do",
        "hello_2",
        register_1.address,
        86400 * 365,
        secret,
        register_1.address,
        zeroBytes32
      );
    });
  });

  //   describe("free register", function () {
  //     it("free register ", async function () {
  //       const duration = 60 * 60 * 24 * 365;
  //       const secondaryNameLength = 2;

  //       // get nonce
  //       const nonce = await nonceGenerator(freeMinter.address, secondaryNameLength, duration);

  //       const { msgHash } = generateMessageHash(
  //         chainId,
  //         RegistrarController.address,
  //         freeMinter.address,
  //         "do",
  //         secondaryNameLength,
  //         nonce,
  //         duration
  //       );

  //       var compactSig = await registrarControllerOwner.signMessage(msgHash);

  //       // construct free mint message
  //       const msg = generateWhitelistMessage(
  //         freeMinter.address,
  //         "do",
  //         secondaryNameLength,
  //         nonce,
  //         duration,
  //         compactSig
  //       );

  //       await RegistrarController.connect(freeMinter).whitelistRegister(
  //         msg,
  //         "do",
  //         ethers.constants.AddressZero
  //       );
  //     });
  //   });

  //   describe("renew", function () {
  //     it("", async function () {});
  //   });

  //   describe("rentPrice", function () {
  //     it("", async function () {});
  //   });

  //   describe("available", function () {
  //     it("", async function () {});
  //   });
});
