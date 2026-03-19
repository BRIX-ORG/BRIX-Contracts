import { ethers } from 'hardhat';

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log('Deploying BrixRegistry with account:', deployer.address);

    // Platform fee address defaults to the deployer
    const platformFeeAddress = deployer.address;

    // IPFS fee: 0.001 MATIC (adjust as needed)
    const ipfsFee = ethers.parseEther('0.001');

    const BrixRegistry = await ethers.getContractFactory('BrixRegistry');
    const registry = await BrixRegistry.deploy(platformFeeAddress, ipfsFee);

    await registry.waitForDeployment();

    const registryAddress = await registry.getAddress();
    console.log('BrixRegistry deployed to:', registryAddress);
    console.log('Platform fee address:', platformFeeAddress);
    console.log('IPFS fee:', ethers.formatEther(ipfsFee), 'MATIC');
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
