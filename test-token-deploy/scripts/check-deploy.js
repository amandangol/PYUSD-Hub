const { ethers } = require("hardhat");

async function main() {
  const contractAddress = "0x074B003f7040D6c8249E09C2e851f63d5072Bed2"; // Replace with actual address
  const provider = new ethers.JsonRpcProvider(process.env.HOLESKY_RPC_URL);

  const code = await provider.getCode(contractAddress);
  if (code === "0x") {
    console.log("Contract not deployed or incorrect address.");
  } else {
    console.log("Contract is deployed at:", contractAddress);
  }
}

main().catch(console.error);
