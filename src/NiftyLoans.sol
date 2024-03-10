// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IERC721 } from "openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "openzeppelin/contracts/access/Ownable.sol";

/**
 * @title   Nifty Loans
 * @notice  This smart contract allows users to collateralize their NFT to receive loans in a
 *          decentralized manner. NFT owners can lock their digital assets in the contract as
 *          collateral to borrow a certain amount of anoter token. The contracts supports a
 *          set of approved NFTs that can be used for these transactions.
 */
contract NiftyLoans is ReentrancyGuard, Ownable {
  /**
   * @dev This struct contrains the details of a loan taken by a borrower.
   * @param borrower The address of the borrower.
   * @param nftAddress The address of the NFT contract being used as collateral.
   * @param nftId The ID of the NFT owned by the borrower.
   * @param loanAmount The amount of the loan.
   * @param loanStartTime The time when the loan was created. If this value is 0, the loan does not exist.
   * @param isRepaid A boolean indicating whether the loan has been repaid.
   */
  struct Loan {
    address borrower;
    address nftAddress;
    uint256 nftId;
    uint256 loanAmount;
    uint256 loanStartTime;
    bool isRepaid;
  }

  /* ==================== State Variables ==================== */

  // Maps borrower address to current loan details
  mapping(address user => Loan loanDetails) public userLoans;

  // Maps NFT address to a bool indicating whether it is an approved collateral;
  mapping(address nftAddress => bool approved) public isCollateralApproved;

  // Maps an nftAddress to its value.
  mapping(address nftAddress => uint256 value) public nftValuation;

  // The token that will be distributed for loans.
  IERC20 public immutable loanToken;

  /* ==================== Events ==================== */

  /**
   * @notice Emmitted when a loan is created.
   * @param borrower The address of the borrower.
   * @param nftAddress The address of the NFT contract being used as collateral.
   * @param nftId The ID of the NFT owned by the borrower.
   * @param loanAmount The amount of the loan.
   */
  event LoanCreated(address indexed borrower, address indexed nftAddress, uint256 indexed nftId, uint256 loanAmount);

  /**
   * @notice Emmitted when a loan is repaid.
   * @param borrower The address of the borrower.
   * @param nftAddress The address of the NFT contract being used as collateral.
   * @param nftId The ID of the NFT owned by the borrower.
   * @param loanAmount The amount of the loan.
   */
  event LoanRepaid(address indexed borrower, address indexed nftAddress, uint256 indexed nftId, uint256 loanAmount);

  /**
   * @notice Emmitted when the value of an nft is updated.
   * @param nftAddress The address of the NFT.
   * @param newValue The new valuation of the NFT.
   *
   */
  event NftValueUpdated(address indexed nftAddress, uint256 newValue);

  /* ==================== Constructor ==================== */

  constructor(IERC20 _loanToken) Ownable(msg.sender) {
    loanToken = _loanToken;
  }

  /* ==================== Restricted Functions ==================== */

  /**
   * @notice Sets the approval status of an NFT as a collateral to the value provided.
   * @param nftAddress The address of the NFT contract.
   * @param approved A boolean indicating whether the NFT is approved.
   */
  function setApprovedCollateral(address nftAddress, bool approved) external onlyOwner {
    isCollateralApproved[nftAddress] = approved;
  }

  /**
   * @notice Sets the value of the NFT with the specified address to the given value.
   * @param nftAddress The address of the NFT contract.
   * @param value The value of the NFT.
   */
  function setNftValue(address nftAddress, uint256 value) external onlyOwner {
    require(isCollateralApproved[nftAddress], "Specified NFT is not approved collateral");
    nftValuation[nftAddress] = value;
  }

  /* ==================== Mutative Functions ==================== */

  /**
   * @notice Allows a user to create a loan using an NFT as collateral.
   * @param nftAddress The address of the NFT contract.
   * @param nftId The ID of the NFT owned by the borrower.
   * @param loanAmount The amount of the loan.
   */
  function createLoan(address nftAddress, uint256 nftId, uint256 loanAmount) external nonReentrant {
    require(isCollateralApproved[nftAddress], "NFT is not approved for collateral");

    IERC721 nft = IERC721(nftAddress);
    require(nft.ownerOf(nftId) == msg.sender, "Sender is not NFT owner");

    uint256 availableFunds = loanToken.balanceOf(address(this));
    require(loanAmount < availableFunds, "Loan amount exceeds available funds");

    uint256 nftValue = nftValuation[nftAddress];
    require(loanAmount <= nftValue, "Loan amount exceeds collateral value");

    userLoans[msg.sender] = Loan({
      borrower: msg.sender,
      nftAddress: nftAddress,
      nftId: nftId,
      loanAmount: loanAmount,
      loanStartTime: block.timestamp,
      isRepaid: false
    });

    nft.transferFrom(msg.sender, address(this), nftId);
    require(loanToken.transfer(msg.sender, loanAmount), "Failed to transfer loan amount");

    emit LoanCreated(msg.sender, nftAddress, nftId, loanAmount);
  }

  /**
   * @notice Allows a user to repay a loan using the loan token.
   */
  function repayLoan() external nonReentrant {
    Loan memory loan = userLoans[msg.sender];

    require(loan.borrower == msg.sender, "Msg sender is not borrower");
    require(loan.loanStartTime != 0, "Loan does not exist");
    require(!loan.isRepaid, "Loan already repaid");

    uint256 repaymentAmount = loan.loanAmount;
    require(loanToken.balanceOf(msg.sender) >= repaymentAmount, "Insufficient amount to repay loan");

    delete userLoans[msg.sender];

    require(loanToken.transferFrom(msg.sender, address(this), repaymentAmount), "Failed to transfer loan amount");
    IERC721(loan.nftAddress).transferFrom(address(this), msg.sender, loan.nftId);

    emit LoanRepaid(msg.sender, loan.nftAddress, loan.nftId, repaymentAmount);
  }

  /* ==================== View Functions ==================== */

  /**
   * @notice Returns the details of the loan taken by the specified borrower.
   * @param borrower The address of the borrower.
   * @return The details of the loan.
   */
  function getLoanDetails(address borrower) external view returns (Loan memory) {
    return userLoans[borrower];
  }
}
