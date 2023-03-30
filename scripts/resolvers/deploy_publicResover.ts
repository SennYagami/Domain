import { ethers, upgrades }  from "hardhat";

const did = "";

async function main() {
    const PublicResolver = await ethers.getContractFactory("PublicResolver");
    console.log("Deploying publicResolver...");
    const publicResolver = await upgrades.deployProxy(PublicResolver, [did], {
    initializer: "initialize",
});
    await publicResolver.deployed();

    console.log("PublicResolver deployed to:", publicResolver.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error({ errMessage: error.message });
    process.exit(1);
  });