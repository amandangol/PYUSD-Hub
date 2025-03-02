const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const TestPYUSD = await ethers.getContractFactory("TestPYUSD");
  const initialSupply = ethers.parseUnits("1000000", 18); // Ensure correct format
  const token = await TestPYUSD.deploy(initialSupply);

  await token.waitForDeployment(); // Replaces .deployed()
  console.log("TestPYUSD deployed to:", await token.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
