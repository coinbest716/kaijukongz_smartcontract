/* hardhat.config.js */
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();

const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1337,
    },
    //  unused configuration commented out for now
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [
        "7deba959ab49d1072e36e26b8b0883d2452f252c2152efa77596bca3a6c79dbd",
      ],
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/1f2b86aeb8724ffea1967dce009e91db",
      accounts: [
        "7deba959ab49d1072e36e26b8b0883d2452f252c2152efa77596bca3a6c79dbd",
      ],
    },
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: ETHERSCAN_API_KEY,
  },
};
