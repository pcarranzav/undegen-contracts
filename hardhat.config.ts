import '@nomicfoundation/hardhat-foundry'
import '@nomicfoundation/hardhat-toolbox'
import '@nomicfoundation/hardhat-ignition-ethers'

import { HardhatUserConfig } from 'hardhat/config'

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.27',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    artifacts: './build/contracts',
    sources: './src',
  },
  networks: {
    hardhat: {
      accounts: {
        mnemonic: 'divide throw butter hazard gauge alpha artwork artefact bike already draw panel',
      },
    },
    baseSepolia: {
      url: 'https://sepolia.base.org',
      accounts: {
        mnemonic: process.env.MNEMONIC ?? '',
      },
    },
  },
}

export default config
