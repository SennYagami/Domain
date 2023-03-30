import { ethers, upgrades }  from "hardhat";

const PROXY = "";

async function main() {
 const PublicResolverV2 = await ethers.getContractFactory("PublicResolverV2");
 console.log("Upgrading publicResolver...");
 await upgrades.upgradeProxy(PROXY, PublicResolverV2);
 console.log("PublicResolver upgraded successfully");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error({ errMessage: error.message });
    process.exit(1);
  });