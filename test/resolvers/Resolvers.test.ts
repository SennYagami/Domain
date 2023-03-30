import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers,upgrades } from "hardhat";
import { PublicResolver, DefaultReverseResolver,DIDRegistry} from "../typechain-types";
import { Wallet } from "ethers";
import { randomHex } from "../../utils/encoding";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { keccak256, toUtf8Bytes,defaultAbiCoder } from "ethers/lib/utils";
import { faucet } from "../../utils/faucet";


describe("Resolvers Test", async function () {

  let publicResolver: PublicResolver;
  let defaultReverseResolver: DefaultReverseResolver;
  let did:DIDRegistry;
  let account0: SignerWithAddress;// example0.did
  let account1: SignerWithAddress;//example1.did
  let example0Node:string;
  let example1Node:string;

  const { provider } = ethers;
  const publicResolverWallet: Wallet = new ethers.Wallet(randomHex(32), provider);
  const defaultReverseResolverWallet: Wallet = new ethers.Wallet(randomHex(32), provider);
 
    console.log({
        publicResolverWallet: defaultReverseResolverWallet.address,
        defaultReverseResolverWallet: defaultReverseResolverWallet.address,
    });

  before(async () => {
    //init contract
    did = await deployRegister();
    publicResolver =await deployPublicResolver(did,publicResolverWallet);
    defaultReverseResolver =await deployDefaultReverseResolver(did,defaultReverseResolverWallet);
    [account0, account1] = await ethers.getSigners();

    //init did data
    example0Node = getBytesTokenId("did","example0");
    example1Node = getBytesTokenId("did","example1");
    await did.connect(account0).setOwner(example0Node, account0.address);
    await did.connect(account1).setOwner(example1Node, account1.address);
  });



  describe("PublicResolver Test", function () {

    it("setAddr should be ok", async function () {
      await publicResolver.connect(account0).setaddr(example0Node,account0.address);
      const value0 = await publicResolver.addr(example0Node);
      expect(value0).to.equal(account0.address);
      await publicResolver.connect(account1).setaddr(example1Node,account1.address);
      const value1 = await publicResolver.addr(example1Node);
      expect(value1).to.equal(account1.address);
    });

    it("setAddr should be exception", async function () {
       expect(await publicResolver.connect(account1).setaddr(example0Node,account0.address).to.be.revertedWith(""));
    });

    it("setName should be ok", async function () {
      await publicResolver.connect(account0).setName(example0Node,"testName");
      const value0 = await publicResolver.name(example0Node);
      expect(value0).to.equal("testName");
      await publicResolver.connect(account1).setName(example1Node,"test1Name");
      const value1 = await publicResolver.name(example1Node);
      expect(value1).to.equal("test1Name");
    });

    it("setName should be exception", async function () {
       expect(await publicResolver.connect(account1).setName(example0Node,"testName").to.be.revertedWith(""));
    });

    it("setText should be ok", async function () {
      await publicResolver.connect(account0).setText(example0Node,"url","https://google.com");
      const value0 = await publicResolver.text(example0Node,"url");
      expect(value0).to.equal("https://google.com");
      await publicResolver.connect(account1).setText(example1Node,"url","https://baidu.com");
      const value1 = await publicResolver.text(example1Node);
      expect(value1).to.equal("https://baidu.com");
    });

    it("setText should be exception", async function () {
       expect(await publicResolver.connect(account1).setText(example0Node,"url","https://google.com").to.be.revertedWith(""));
    });

    it("setCommissionAcceptAddress should be ok", async function () {
      await publicResolver.connect(account0).setCommissionAcceptAddress(example0Node,account0.address);
      const value0 = await publicResolver.commissionAcceptAddress(example0Node);
      expect(value0).to.equal(account0.address);
      await publicResolver.connect(account1).setCommissionAcceptAddress(example1Node,account1.address);
      const value1 = await publicResolver.commissionAcceptAddress(example1Node);
      expect(value1).to.equal(account1.address);
    });

    it("setCommissionAcceptAddress should be exception", async function () {
       expect(await publicResolver.connect(account1).setCommissionAcceptAddress(example0Node,account1.address).to.be.revertedWith(""));
    });
 
  });

});




async function deployRegister() {
    const DIDRegistry = await ethers.getContractFactory("DIDRegistry");
    console.log("Deploying DIDRegistry...");
    const didRegistry = await upgrades.deployProxy(DIDRegistry,  {
    initializer: "initialize",
});
    await didRegistry.deployed();
    console.log("DIDRegistry deployed to:", didRegistry.address);
    return didRegistry
}


async function deployPublicResolver(did:any,wallet:Wallet) {
    const PublicResolver = await ethers.getContractFactory("PublicResolver");
    console.log("Deploying PublicResolver...");
    const publicResolver = await PublicResolver.deploy(did,Wallet);
    await publicResolver.deployed();
    console.log("PublicResolver deployed to:", publicResolver.address);
    return publicResolver
}

async function deployDefaultReverseResolver(did:any,wallet:Wallet) {
    const DefaultReverseResolver = await ethers.getContractFactory("DefaultReverseResolver");
    console.log("Deploying DefaultReverseResolver...");
    const defaultReverseResolver = await DefaultReverseResolver.deploy(did,Wallet);
    await defaultReverseResolver.deployed();

    console.log("DefaultReverseResolver deployed to:", defaultReverseResolver.address);
    return defaultReverseResolver
}

function getBytesTokenId(rootName: string, secondaryName: string) {
  const firstHash = keccak256(
    defaultAbiCoder.encode(
      ["address", "bytes32"],
      [ethers.constants.AddressZero, keccak256(toUtf8Bytes(rootName))]
    )
  );

  const tokenId = keccak256(
    defaultAbiCoder.encode(
      ["bytes32", "bytes32"],
      [firstHash, keccak256(toUtf8Bytes(secondaryName))]
    )
  );

  return tokenId;
}