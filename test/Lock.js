// Import necessary Hardhat modules and assertions
const { ethers } = require("hardhat");
const { expect } = require("chai");

// Define variables for contract instances and accounts
let VunaVault;
let vunaVault;
let owner;
let user;
let testToken;
let TestToken;

// Deploy the VunaVault contract before each test
beforeEach(async () => {
  VunaVault = await ethers.getContractFactory("VunaVault");
  TestToken = await ethers.getContractFactory("TestToken");
  [owner, user] = await ethers.getSigners();

  testToken = await TestToken.deploy();

  await testToken.mint(owner.address, ethers.parseEther('10'))

  vunaVault = await VunaVault.deploy(
    /* _usableToken */ testToken.getAddress(),
    /* feeVault */ user.address,
    /* _fee */ ethers.parseEther('1')
  );
});

// Test case for creating a target
describe("createTarget", () => {
  it("should create a target with valid parameters", async () => {
    const targetAmount = 5000;
    const contributionPerTurn = 50;
    const duration = 12;

    // Ensure the user has some tokens to cover the fee
    //await testToken.connect(owner).transfer(user.address, 100);

    // Approve the contract to spend tokens on behalf of the user
    console.log(await testToken.balanceOf(owner.address))
    await testToken.connect(user).increaseAllowance(vunaVault.getAddress(), ethers.parseEther('10'));

    // Create the target
    await expect(
      vunaVault.connect(owner).createTarget(targetAmount, contributionPerTurn, duration)
    ).to.emit(vunaVault, "TargetSavingsCreated");

    // Additional assertions can be added based on the contract's logic
  });
});

// Test case for contributing to a target
describe("contribute", () => {
  it("should contribute to an existing target", async () => {
    const targetID = 1;

    // Ensure the user has some tokens to contribute
    await token.connect(owner).transfer(user.address, 100);

    // Approve the contract to spend tokens on behalf of the user
    await token.connect(user).approve(vunaVault.address, 1);

    // Contribute to the target
    await expect(
      vunaVault.connect(user).contribute(targetID)
    ).to.not.be.reverted;

    // Additional assertions can be added based on the contract's logic
  });
});

// Test case for withdrawing savings
describe("WithdrawSavings", () => {
  it("should withdraw savings from an existing target", async () => {
    const targetID = 1;

    // Ensure the user has some tokens to cover the fee
    await token.connect(owner).transfer(user.address, 100);

    // Approve the contract to spend tokens on behalf of the user
    await token.connect(user).approve(vunaVault.address, 1);

    // Create a target
    await vunaVault.connect(user).createTarget(5000, 50, 12);

    // Contribute to the target
    await vunaVault.connect(user).contribute(targetID);

    // Withdraw savings
    await expect(
      vunaVault.connect(user).WithdrawSavings(targetID)
    ).to.not.be.reverted;

    // Additional assertions can be added based on the contract's logic
  });
});

// Additional test cases and edge cases can be added based on the contract's functionality
