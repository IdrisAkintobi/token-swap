import { expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import { MockERC20, TokenSwap } from "../typechain-types";

describe("TokenSwap", function () {
  let tokenSwap: TokenSwap;
  let owner: Signer, addr1: Signer, addr2: Signer;
  let guzToken: MockERC20, w3bToken: MockERC20;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy TokenSwap contract
    const TokenSwap = await ethers.getContractFactory("TokenSwap");
    tokenSwap = await TokenSwap.deploy();

    // Deploy two mock ERC20 tokens (GUZ and W3B)
    const ERC20 = await ethers.getContractFactory("MockERC20");
    guzToken = await ERC20.deploy("GUZ Token", "GUZ");
    w3bToken = await ERC20.deploy("W3B Token", "W3B");

    // Mint tokens to addr1 and addr2
    await guzToken.mint(
      await addr1.getAddress(),
      ethers.parseUnits("1000", 18)
    );
    await w3bToken.mint(
      await addr2.getAddress(),
      ethers.parseUnits("1000", 18)
    );
  });

  it("Should revert if offer amount is zero", async function () {
    await expect(
      tokenSwap
        .connect(addr1)
        .createOrder(guzToken, 0, w3bToken, ethers.parseUnits("20", 18))
    ).to.be.revertedWithCustomError(
      tokenSwap,
      "OfferAmountMustBeGreaterThanZero"
    );
  });

  it("Should revert if want amount is zero", async function () {
    await expect(
      tokenSwap
        .connect(addr1)
        .createOrder(guzToken, ethers.parseUnits("100", 18), w3bToken, 0)
    ).to.be.revertedWithCustomError(
      tokenSwap,
      "WantAmountMustBeGreaterThanZero"
    );
  });

  it("Should revert if insufficient allowance", async function () {
    await expect(
      tokenSwap
        .connect(addr1)
        .createOrder(
          guzToken,
          ethers.parseUnits("100", 18),
          w3bToken,
          ethers.parseUnits("20", 18)
        )
    ).to.be.revertedWithCustomError(tokenSwap, "InsufficientAllowance");
  });

  it("Should revert if insufficient balance", async function () {
    // Give the contract sufficient allowance
    await guzToken
      .connect(addr1)
      .approve(tokenSwap, ethers.parseUnits("2000", 18)); // Higher allowance

    // Try to create an order with more tokens than addr1's balance
    await expect(
      tokenSwap.connect(addr1).createOrder(
        guzToken,
        ethers.parseUnits("2000", 18), // More than the balance
        w3bToken,
        ethers.parseUnits("20", 18)
      )
    ).to.be.revertedWithCustomError(tokenSwap, "InsufficientBalance");
  });

  it("Should allow the owner to approve the order", async function () {
    await guzToken
      .connect(addr1)
      .approve(tokenSwap, ethers.parseUnits("100", 18));
    await tokenSwap
      .connect(addr1)
      .createOrder(
        guzToken,
        ethers.parseUnits("100", 18),
        w3bToken,
        ethers.parseUnits("20", 18)
      );

    await tokenSwap.connect(owner).approveOrder(1);
    const order = await tokenSwap.orders(1);
    expect(order.approved).to.be.true;
  });

  it("Should allow the order creator to cancel the order", async function () {
    await guzToken
      .connect(addr1)
      .approve(tokenSwap, ethers.parseUnits("100", 18));
    await tokenSwap
      .connect(addr1)
      .createOrder(
        guzToken,
        ethers.parseUnits("100", 18),
        w3bToken,
        ethers.parseUnits("20", 18)
      );

    await tokenSwap.connect(addr1).cancelOrder(1);
    const order = await tokenSwap.orders(1);
    expect(order.canceled).to.be.true;
  });

  it("Should revert if non-owner tries to approve the order", async function () {
    await guzToken
      .connect(addr1)
      .approve(tokenSwap, ethers.parseUnits("100", 18));
    await tokenSwap
      .connect(addr1)
      .createOrder(
        guzToken,
        ethers.parseUnits("100", 18),
        w3bToken,
        ethers.parseUnits("20", 18)
      );

    // Expect the error OwnableUnauthorizedAccount when a non-owner tries to approve the order
    await expect(
      tokenSwap.connect(addr2).approveOrder(1)
    ).to.be.revertedWithCustomError(tokenSwap, "OwnableUnauthorizedAccount");
  });
});
