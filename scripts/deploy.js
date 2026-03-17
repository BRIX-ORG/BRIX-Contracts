const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Platform fee address defaults to the deployer for this example
  const platformFeeAddress = deployer.address;

  // Get the ContractFactory
  const Donate = await hre.ethers.getContractFactory("Donate");

  // Deploy the contract
  const donate = await Donate.deploy(platformFeeAddress);

  // Wait for the deployment to finish
  await donate.waitForDeployment();

  const donateAddress = await donate.getAddress();
  console.log("Donate contract deployed to:", donateAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
