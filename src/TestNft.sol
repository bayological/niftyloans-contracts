// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestNFT is ERC721Enumerable, Ownable {
  constructor() ERC721("TestNFT", "TNFT") Ownable(msg.sender) {}

  function mint(address to, uint256 tokenId) public onlyOwner {
    _mint(to, tokenId);
  }
}
