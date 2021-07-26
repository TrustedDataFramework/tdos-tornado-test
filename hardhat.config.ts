import "@nomiclabs/hardhat-waffle"
import 'hardhat-deploy'

export default {
  solidity: {
    version: '0.5.17',
    settings: {
      optimizer: { enabled: true, runs: 200 },
      evmVersion: 'istanbul'
    },
  },
  networks: {
    localhost: {
      url: 'http://127.0.0.1:8545',
      accounts: [process.env.PRIVATE_KEY]
    },
    bscTest: {
      url: 'https://data-seed-prebsc-1-s1.binance.org:8545/',
      accounts: [process.env.PRIVATE_KEY]
    },
    tdos: {
      url: 'http://192.168.1.28:7010',
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};

