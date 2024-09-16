import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { Contract } from "ethers";

/**
 * Deploys a contract named "Vendor" using the deployer account and
 * constructor arguments set to the deployer address
 *
 * @param hre HardhatRuntimeEnvironment object.
 */
// eslint-disable-next-line @typescript-eslint/no-unused-vars
// Nick's notes: This function is responsible for deploying the Vendor contract and setting it up
const deployVendor: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  /*
    On localhost, the deployer account is the one that comes with Hardhat, which is already funded.

    When deploying to live networks (e.g `yarn deploy --network goerli`), the deployer account
    should have sufficient balance to pay for the gas fees for contract creation.

    You can generate a random account with `yarn generate` which will fill DEPLOYER_PRIVATE_KEY
    with a random private key in the .env file (then used on hardhat.config.ts)
    You can run the `yarn account` command to check your balance in every network.
  */
  // Deploy Vendor
  const { deployer } = await hre.getNamedAccounts();  // We're using named accounts here, which are defined in the Hardhat config
  const { deploy } = hre.deployments;
  const yourToken = await hre.ethers.getContract<Contract>("YourToken", deployer);  // We're getting the YourToken contract that should have been deployed previously
  const yourTokenAddress = await yourToken.getAddress();
  // This is where we actually deploy the Vendor contract
  await deploy("Vendor", {
    from: deployer,
    // Contract constructor arguments
    args: [yourTokenAddress],
    log: true,
    // autoMine: can be passed to the deploy function to make the deployment process faster on local networks by
    // automatically mining the contract deployment transaction. There is no effect on live networks.
    autoMine: true,
  });

  const vendor = await hre.ethers.getContract<Contract>("Vendor", deployer);  // After deployment, we get a reference to the deployed Vendor contract
  const vendorAddress = await vendor.getAddress();
  // Transfer tokens to Vendor
  // We're transferring tokens to the Vendor contract for initial liquidity
  await yourToken.transfer(vendorAddress, hre.ethers.parseEther("1000"));
  // Transfer contract ownership to your frontend address
  await vendor.transferOwnership("0x48Bf488D00FE4C83e803688ffE5532EB83E9a0ff");
};

export default deployVendor;

// Tags are useful if you have multiple deploy files and only want to run one of them.
// e.g. yarn deploy --tags Vendor
deployVendor.tags = ["Vendor"];
