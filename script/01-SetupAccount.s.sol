// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script, console2 } from "forge-std/Script.sol";
import { NiftyLoans } from "src/NiftyLoans.sol";
import { TestNFT } from "src/TestNft.sol";
import { TestToken } from "src/TestToken.sol";

// 1. Run local fork of testnet using anvil -> npm run fork:start
//
// 2. Run command to execute script on fork -> npm run fork:setup
//
contract SetupAccount is Script {
  function run() public {
    uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
    address testNftAddress = vm.envAddress("NFT_ADDRESS");
    address testTokenAddress = vm.envAddress("TOKEN_ADDRESS");
    address niftyLoansAddress = vm.envAddress("NIFTY_ADDRESS");
    address testBorrower = vm.envAddress("TEST_BORROWER");

    vm.startBroadcast(deployerPrivateKey);
    {
      console2.log("Running setup ....");
      console2.log("=====================================");

      // Mint NFTs to test address
      TestNFT testNFT = TestNFT(testNftAddress);
      testNFT.mint(testBorrower, 1);
      testNFT.mint(testBorrower, 3);
      testNFT.mint(testBorrower, 5);

      // // Mint some test tokens and give to the contract
      TestToken testToken = TestToken(testTokenAddress);
      testToken.mint(niftyLoansAddress, 100 ether);

      // Set value of NFTs
      NiftyLoans niftyLoans = NiftyLoans(niftyLoansAddress);
      niftyLoans.setNftValue(testNftAddress, 300 ether);

      // Transfer some lineaEth to the test borrower using deployer acccount
      (bool sent, ) = testBorrower.call{ value: 10 ether }("");
      require(sent, "Failed to send Ether");

      console2.log("=====================================");
    }
    vm.stopBroadcast();
  }
}
