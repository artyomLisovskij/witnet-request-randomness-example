require("@nomicfoundation/hardhat-ethers");
require("hardhat-contract-sizer");
require('dotenv').config({path:__dirname+'/.env'})
const { RPC_URL, PRIVATE_KEY } = process.env

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  defaultNetwork: "mynetwork",
  networks: {
    mynetwork: {
      url: RPC_URL,
      accounts: [ PRIVATE_KEY] 
    }
  },
};
