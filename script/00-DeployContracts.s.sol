// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script, console2 } from "forge-std/Script.sol";
import { NiftyLoans } from "src/NiftyLoans.sol";
import { TestNFT } from "src/TestNft.sol";
import { TestToken } from "src/TestToken.sol";

// 1. Run local fork of testnet using anvil -> npm run fork:start
//
// 2. Run command to execute script on fork -> npm run fork:deploy
//
contract DeployContracts is Script {
  function run() public {
    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

    vm.startBroadcast(deployerPrivateKey);
    {
      console2.log("Deploying contracts....");
      console2.log("=====================================");

      // Deploy test token
      TestToken testToken = new TestToken();
      console2.log("TestToken deployed at: ", address(testToken));

      // Deploy test NFT
      TestNFT testNFT = new TestNFT();
      console2.log("TestNFT deployed at: ", address(testNFT));

      // Deploy NiftyLoans
      NiftyLoans niftyLoans = new NiftyLoans(testToken);
      console2.log("NiftyLoans deployed at: ", address(niftyLoans));

      // Set nft as approved collateral
      niftyLoans.setApprovedCollateral(address(testNFT), true);
      console2.log("TestNFT set as approved collateral ....");

      console2.log("=====================================");
    }
    vm.stopBroadcast();
  }
}
