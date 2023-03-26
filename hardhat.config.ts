import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
<<<<<<< HEAD
require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    hardhat: { allowUnlimitedContractSize: false },
    goerli: {
      chainId: 5,
      url: process.env.ALCHEMY_API,
=======
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-etherscan";
require("dotenv").config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      { version: "0.6.12" },
      { version: "0.5.17" },
      { version: "0.7.6" },
      { version: "0.8.17" },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
    },
  },
  networks: {
    hardhat: { allowUnlimitedContractSize: true },
    mumbai: {
      chainId: 80001,
      url: process.env.ALCHEMY_API_MUMBAI,
>>>>>>> 39883efe77abf7fda276f3c4a651afc156de2c4e
      accounts: [
        process.env.DEPLOYER as string,
        process.env.MULTISIGWALLETOWNER1 as string,
        process.env.MULTISIGWALLETOWNER2 as string,
        process.env.MULTISIGWALLETOWNER3 as string,
        process.env.ACCEPTER as string,
      ],
      gas: 10000000,
      //   allowUnlimitedContractSize: true,
    },
<<<<<<< HEAD
    mumbai: {
      chainId: 80001,
      url: process.env.MUMBAI_API,
=======
    polygon: {
      chainId: 137,
      url: process.env.ALCHEMY_API,
>>>>>>> 39883efe77abf7fda276f3c4a651afc156de2c4e
      accounts: [
        process.env.DEPLOYER as string,
        process.env.MULTISIGWALLETOWNER1 as string,
        process.env.MULTISIGWALLETOWNER2 as string,
        process.env.MULTISIGWALLETOWNER3 as string,
        process.env.ACCEPTER as string,
      ],
<<<<<<< HEAD
      gas: 1000000,
      //   allowUnlimitedContractSize: true,
    },
  },
=======
      gas: 10000000,
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.ETHERSCAN_API_KEY as string,
      polygon: process.env.ETHERSCAN_API_KEY as string
    }
  }
>>>>>>> 39883efe77abf7fda276f3c4a651afc156de2c4e
};

export default config;