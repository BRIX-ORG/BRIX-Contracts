import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-gas-reporter';
import 'solidity-coverage';
import * as dotenv from 'dotenv';
dotenv.config();

const config: HardhatUserConfig = {
    solidity: '0.8.28',
    networks: {
        hardhat: {},
        amoy: {
            url: process.env.POLYGON_AMOY_RPC_URL || 'https://polygon-amoy.drpc.org',
            accounts: process.env.PRIVATE_KEY
                ? [process.env.PRIVATE_KEY.trim().replace(/^["']|["']$/g, '')]
                : [],
        },
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS !== undefined,
        currency: 'USD',
    },
    etherscan: {
        apiKey: process.env.ETHERSCAN_API_KEY || '',
        customChains: [
            {
                network: 'polygonAmoy',
                chainId: 80002,
                urls: {
                    apiURL: 'https://api-amoy.polygonscan.com/api/v2',
                    browserURL: 'https://amoy.polygonscan.com',
                },
            },
        ],
    },
};

export default config;
