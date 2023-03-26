import hre from "hardhat";
import { ethers } from "ethers";

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());
  const RegistrarControllerForTestFactory = await hre.ethers.getContractFactory(
    "RegistrarControllerForTest"
  );
  //   create and initialize checkExecutor using multiContractWallet.address
  const RegistrarControllerForTest = await RegistrarControllerForTestFactory.deploy(
    ethers.constants.AddressZero,
    ethers.constants.AddressZero,
    ethers.constants.AddressZero,
    15,
    86400,
    ethers.constants.AddressZero
  );
  console.log(RegistrarControllerForTest.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error({ errMessage: error.message });
    process.exit(1);
  });
