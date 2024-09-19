# Token Swap Project

This is a simple token swap project built using Solidity and Hardhat. The project allows users to create orders to swap ERC20 tokens, approve or decline them as the owner, and fulfill orders by other users.

## Features:

- Users can create swap orders offering one token in exchange for another.
- Only the contract owner can approve or decline orders.
- Low-level calls are used for token transfers, and reentrancy is prevented by updating balances before transfers.
- Token transfers are made with a specified gas limit.

## Prerequisites

To use the project, make sure you have the following installed:

- [Node.js](https://nodejs.org/) (v18 or higher)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)
- [Hardhat](https://hardhat.org/)

## Setup Instructions

1. **Clone the repository**:

   ```bash
   git clone https://github.com/IdrisAkintobi/token-swap.git
   cd token-swap-project
   ```

2. **Install dependencies**:
   Run the following command to install the required npm packages.

   ```bash
   npm install
   ```

3. **Compile the contracts**:
   Compile the Solidity contracts with Hardhat using:

   ```bash
   npm run build
   ```

4. **Run tests**:
   To run the unit tests, use the command:

   ```bash
   npm test
   ```

5. **Start a local blockchain**:
   Start a local Hardhat node:

   ```bash
   npm run start:node
   ```

6. **Deploy the contract locally**:
   Deploy the smart contract to the local Hardhat network:

   ```bash
   npm run deploy:local
   ```

7. **Interact with the contract**:
   Run the interaction script to create and fulfill token swap orders:

   ```bash
   npm run interact
   ```

8. **Deploy to a test network**:
   Before deploying to a test network (e.g., Sepolia), make sure to set up your environment variables for deployment:
   ```bash
   npm run deploy
   ```

## Project Structure

- **contracts/**: Contains Solidity contracts.
- **scripts/**: Scripts for deploying and interacting with the contracts.
- **test/**: Unit tests for the contracts.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [OpenZeppelin](https://openzeppelin.com/) for the ERC20 token implementation.
- [Hardhat](https://hardhat.org/) for the development environment.
