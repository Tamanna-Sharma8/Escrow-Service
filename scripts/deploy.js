const { ethers } = require("hardik");

async function main() {
  console.log("Starting deployment of Escrow Service...");
  
  // Get the ContractFactory and Signers
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)));
  
  // Deploy the contract
  const Project = await ethers.getContractFactory("Project");
  const project = await Project.deploy();
  
  await project.waitForDeployment();
  
  const contractAddress = await project.getAddress();
  
  console.log("✅ Escrow Service deployed successfully!");
  console.log("📋 Contract Address:", contractAddress);
  console.log("🌐 Network:", hre.network.name);
  console.log("⛽ Gas Used: Contract deployment completed");
  
  // Verify contract deployment
  console.log("\n📊 Contract Details:");
  console.log("- Contract Owner:", await project.owner());
  console.log("- Service Fee Rate:", (await project.serviceFeeRate()).toString() + " basis points");
  console.log("- Total Transactions:", (await project.getTotalTransactions()).toString());
  console.log("- Contract Balance:", ethers.formatEther(await project.getContractBalance()) + " ETH");
  
  // Save deployment information
  const deploymentInfo = {
    contractAddress: contractAddress,
    deployer: deployer.address,
    network: hre.network.name,
    blockNumber: await ethers.provider.getBlockNumber(),
    timestamp: new Date().toISOString(),
    gasUsed: "See transaction receipt"
  };
  
  console.log("\n💾 Deployment Information:");
  console.log(JSON.stringify(deploymentInfo, null, 2));
  
  // Instructions for interaction
  console.log("\n📝 Next Steps:");
  console.log("1. Save the contract address:", contractAddress);
  console.log("2. Verify the contract on the explorer if needed");
  console.log("3. Test the contract functions:");
  console.log("   - createEscrow(seller_address, description)");
  console.log("   - releaseFunds(transaction_id)");
  console.log("   - initiateDispute(transaction_id)");
  console.log("4. Update your frontend/dApp with the new contract address");
  
  return contractAddress;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:");
    console.error(error);
    process.exit(1);
  });
