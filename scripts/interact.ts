import { ethers } from "hardhat";

async function main() {
    const [owner, addr1, addr2] = await ethers.getSigners();

    // Deploy TokenSwap contract
    const TokenSwap = await ethers.getContractFactory("TokenSwap");
    const tokenSwap = await TokenSwap.deploy();
    console.log("TokenSwap deployed to:", await tokenSwap.getAddress());

    // Deploy MockERC20 tokens
    const MockERC20 = await ethers.getContractFactory("MockERC20");
    const guzToken = await MockERC20.deploy("GUZ Token", "GUZ");
    const w3bToken = await MockERC20.deploy("W3B Token", "W3B");
    console.log("GUZ Token deployed to:", await guzToken.getAddress());
    console.log("W3B Token deployed to:", await w3bToken.getAddress());

    // Mint tokens
    await guzToken.mint(addr1.address, ethers.parseUnits("1000", 18));
    await w3bToken.mint(addr2.address, ethers.parseUnits("1000", 18));

    // Approve TokenSwap contract to spend GUZ tokens for addr1
    await guzToken
        .connect(addr1)
        .approve(tokenSwap, ethers.parseUnits("100", 18));

    // Create an order: addr1 offers 100 GUZ for 20 W3B
    await tokenSwap
        .connect(addr1)
        .createOrder(
            guzToken,
            ethers.parseUnits("100", 18),
            w3bToken,
            ethers.parseUnits("20", 18)
        );
    console.log("Order created by addr1: 100 GUZ for 20 W3B");

    // Approve the order as the owner
    await tokenSwap.connect(owner).approveOrder(1);
    console.log("Order approved by owner");

    // Approve TokenSwap contract to spend W3B tokens for addr2
    await w3bToken
        .connect(addr2)
        .approve(tokenSwap, ethers.parseUnits("20", 18));

    // Fulfill the order: addr2 fulfills it by providing 20 W3B
    await tokenSwap.connect(addr2).fulfillOrder(1, 50000); // Specify gas limit
    console.log("Order fulfilled by addr2: 20 W3B for 100 GUZ");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
