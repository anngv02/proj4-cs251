Stanford University, CS251 Project 4: Building a DEX
Authors: Gordon Martinez-Piedra Tao (BS'23, MS'24) under the guidance of Professor Dan Boneh.
# <span style="color: blue;">Token Exchange Project</span>

This project implements a simple token exchange on the Ethereum blockchain, using Hardhat, ethers.js, and OpenZeppelin.

## <span style="color: green;">Description</span>

The project includes:

* **contracts/token.sol:** ERC-20 token smart contract.
* **contracts/exchange.sol:** Exchange smart contract.
* **web_app/exchange.js:** JavaScript backend for the web application.
* **web_app/index.html:** HTML frontend for the web application.

## <span style="color: orange;">Setup</span>

1.  **Install Node.js:**
    * Download and install Node.js (versions V12.xx, 14.xx, or 16.xx are supported).
    * Previous releases can be found [here](<https://nodejs.org/en>).
2.  **Download Project Source Code:**
    * **Using Git (recommended):**
        * Open your terminal and navigate to the directory where you want to store the project.
        * Run the following command to clone the project:
            ```bash
            git clone https://github.com/anngv02/proj4-cs251
            ```
    * **Manual Download:**
        * Visit the project's GitHub repository page.
        * Click the "Code" button and select "Download ZIP".
        * Extract the ZIP file to your desired directory.
3.  **Navigate to Project Directory:**
    * Open your terminal and `cd` into the extracted starter code directory.
4.  **Install Hardhat:**
    * Run `npm install --save-dev hardhat` to install the Hardhat Ethereum development environment.
    * If you encounter Node.js version compatibility errors, install a supported version and use `nvm use <version>` to switch.
5.  **Install Hardhat Ethers Plugin:**
    * Run `npm install --save-dev @nomiclabs/hardhat-ethers ethers` to install the plugin for deploying Hardhat nodes.
6.  **Install OpenZeppelin Contracts:**
    * Run `npm install --save-dev @openzeppelin/contracts` to install the OpenZeppelin libraries.

## <span style="color: purple;">Compile, Deploy, and Test</span>

1.  **Modify Contracts and Backend:**
    * Modify `contracts/token.sol` and `contracts/exchange.sol` to define your Solidity contracts.
    * Modify `web_app/exchange.js` to build the JavaScript backend.
    * Refer to other files for Hardhat node and web client understanding.
    * Implement functions in designated areas and add helper functions as needed.
    * **Important:** Do not modify any other code or install additional node packages.
2.  **Review Documentation:**
    * Peruse the starter code, ethers.js documentation, Solidity documentation, and OpenZeppelin ERC-20 contract implementation.
    * Plan the system design, considering on-chain data storage and contract vs. client-side computations.
3.  **Start Local Node:**
    * Run `npx hardhat node` to start the local Hardhat node.
    * Successful startup will display: `Started HTTP and WebSocket JSON-RPC server at http://127.0.0.1:8545/`.
4.  **Deploy Token Contract:**
    * Open a new terminal tab/window and `cd` into the starter code directory.
    * Run `npx hardhat run --network localhost scripts/deploy_token.js` to compile and deploy the token contract.
    * Upon success, the terminal will display: `Successfully wrote token address <token_address> to token_address.txt`.
    * Copy the `<token_address>` and paste it into the `address tokenAddr` field in `contracts/exchange.sol` or copy it from `token_address.txt`.
5.  **Deploy Exchange Contract:**
    * Run `npx hardhat run --network localhost scripts/deploy_exchange.js` to deploy the exchange contract.
    * Upon success, the terminal will display: `Successfully wrote exchange address <exchange_address> to exchange_address.txt`.
    * Copy the `<exchange_address>` and save it for the next step or copy it from `exchange_address.txt`.
6.  **Update JavaScript Backend:**
    * Update `web_app/exchange.js` with the contract addresses and ABIs.
    * Replace `const token_address` and `const exchange_address` with the addresses from steps 4 and 5.
    * Copy the ABIs from `artifacts/contracts/token.sol/token.json` (after the `abi` field, including the square brackets) and `artifacts/contracts/exchange.sol/exchange.json`.
    * Ensure your contract address is a string.
7.  **Open Web Application:**
    * Open `web_app/index.html` in your web browser.
    * You can interact with the page.

## <span style="color: red;">Contributing</span>

If you'd like to contribute to this project, please create a pull request.