const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log(
    "Account balance:",
    (await ethers.provider.getBalance(deployer.address)).toString()
  );

  const TestPYUSD = await ethers.getContractFactory("TestPYUSD");
  const decimals = 6;
  const initialSupply = 1000000; // 1 million tokens

  console.log(
    `Deploying TestPYUSD with initial supply of ${initialSupply} tokens (with ${decimals} decimals)`
  );

  const token = await TestPYUSD.deploy(initialSupply);
  await token.waitForDeployment();

  const tokenAddress = await token.getAddress();
  console.log("TestPYUSD deployed to:", tokenAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
