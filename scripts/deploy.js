const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying Multi-signature Wallet to Core Testnet 2...\n");

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Define wallet owners (replace with actual addresses)
  const owners = [
    deployer.address, // First owner is the deployer
    "0x742d35Cc6634C0532925a3b8D9C0aC3C7C1B5C8D", // Replace with actual address
    "0x8ba1f109551bD432803012645Hac136c5cb8BF7C", // Replace with actual address
  ];

  // Number of confirmations required (2 out of 3)
  const numConfirmationsRequired = 2;

  console.log("Wallet owners:", owners);
  console.log("Required confirmations:", numConfirmationsRequired);

  // Deploy the contract
  const Project = await ethers.getContractFactory("Project");
  const project = await Project.deploy(owners, numConfirmationsRequired);

  await project.deployed();

  console.log("\n✅ Multi-signature Wallet deployed successfully!");
  console.log("Contract address:", project.address);
  console.log("Transaction hash:", project.deployTransaction.hash);
  console.log("Gas used:", project.deployTransaction.gasLimit.toString());

  // Verify deployment
  console.log("\n📋 Deployment Summary:");
  console.log("==========================================");
  console.log("Contract Name: Multi-signature Wallet");
  console.log("Network: Core Testnet 2");
  console.log("Contract Address:", project.address);
  console.log("Owners:", await project.getOwners());
  console.log("Required Confirmations:", await project.numConfirmationsRequired());
  console.log("Initial Transaction Count:", await project.getTransactionCount());

  // Optional: Send some test ETH to the wallet
  if (process.env.FUND_WALLET === "true") {
    console.log("\n💰 Funding the wallet with test ETH...");
    const fundTx = await deployer.sendTransaction({
      to: project.address,
      value: ethers.utils.parseEther("1.0"), // Send 1 ETH
    });
    await fundTx.wait();
    console.log("Wallet funded with 1 ETH");
  }

  console.log("\n🔗 Explorer Link:");
  console.log(`https://scan.test2.btcs.network/address/${project.address}`);

  console.log("\n📝 Next Steps:");
  console.log("1. Verify the contract on the explorer");
  console.log("2. Test the wallet functionality");
  console.log("3. Add more owners if needed");
  console.log("4. Start using the multi-signature wallet!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ Deployment failed:");
    console.error(error);
    process.exit(1);
  });
