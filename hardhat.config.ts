import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-gas-reporter';
import 'solidity-coverage';
import * as dotenv from 'dotenv';

dotenv.config();

const config: HardhatUserConfig = {
    solidity: '0.8.34',
    networks: {
        hardhat: {},
        amoy: {
            url: process.env.POLYGON_AMOY_RPC_URL || 'https://rpc-amoy.polygon.technology/',
            accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
        },
        mumbai: {
            url: process.env.POLYGON_MUMBAI_RPC_URL || '',
            accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
        },
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS !== undefined,
        currency: 'USD',
    },
};

export default config;
