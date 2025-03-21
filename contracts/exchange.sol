// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import './token.sol';
import "hardhat/console.sol";


contract TokenExchange is Ownable {
    string public exchange_name = 'AnnezSwap';

    // TODO: paste token contract address here
    // e.g. tokenAddr = 0x5FbDB2315678afecb367f032d93F642f64180aa3
    address tokenAddr = 0x5FbDB2315678afecb367f032d93F642f64180aa3;                                  // TODO: paste token contract address here
    Token public token = Token(tokenAddr);                                

    // Liquidity pool for the exchange
    uint private token_reserves = 0;
    uint private eth_reserves = 0;

    // Fee Pools
    uint private token_fee_reserves = 0;
    uint private eth_fee_reserves = 0;

    // Liquidity pool shares
    mapping(address => uint) private lps;

    // For Extra Credit only: to loop through the keys of the lps mapping
    address[] private lp_providers;      

    // Total Pool Shares
    uint private total_shares = 0;

    // liquidity rewards
    uint private swap_fee_numerator = 3;                
    uint private swap_fee_denominator = 100;

    // Constant: x * y = k
    uint private k;

    uint private multiplier = 10**12;

    constructor() {}

    // event Swap(address indexed user, uint inputAmount, uint outputAmount, bool isEthToToken);
    // event LiquidityAdded(address indexed provider, uint ethAmount, uint tokenAmount);
    // event LiquidityRemoved(address indexed provider, uint ethAmount, uint tokenAmount);
    

    // Function createPool: Initializes a liquidity pool between your Token and ETH.
    // ETH will be sent to pool in this transaction as msg.value
    // amountTokens specifies the amount of tokens to transfer from the liquidity provider.
    // Sets up the initial exchange rate for the pool by setting amount of token and amount of ETH.
    function createPool(uint amountTokens)
        external
        payable
        onlyOwner
    {
        // This function is already implemented for you; no changes needed.

        // require pool does not yet exist:
        require (token_reserves == 0, "Token reserves was not 0");
        require (eth_reserves == 0, "ETH reserves was not 0.");

        // require nonzero values were sent
        require (msg.value > 0, "Need eth to create pool.");
        uint tokenSupply = token.balanceOf(msg.sender);
        require(amountTokens <= tokenSupply, "Not have enough tokens to create the pool");
        require (amountTokens > 0, "Need tokens to create pool.");

        token.transferFrom(msg.sender, address(this), amountTokens);
        token_reserves = token.balanceOf(address(this));
        eth_reserves = msg.value;
        k = token_reserves * eth_reserves;

        // Pool shares set to a large value to minimize round-off errors
        total_shares = 10**5;
        // Pool creator has some low amount of shares to allow autograder to run
        lps[msg.sender] = 100;
    }

    // For use for ExtraCredit ONLY
    // Function removeLP: removes a liquidity provider from the list.
    // This function also removes the gap left over from simply running "delete".
    function removeLP(uint index) private {
        require(index < lp_providers.length, "specified index is larger than the number of lps");
        lp_providers[index] = lp_providers[lp_providers.length - 1];
        lp_providers.pop();
    }

    // Function getSwapFee: Returns the current swap fee ratio to the client.
    function getSwapFee() public view returns (uint, uint) {
        return (swap_fee_numerator, swap_fee_denominator);
    }

    // Function getReserves
    function getReserves() public view returns (uint, uint) {
        return (eth_reserves, token_reserves);
    }

    // ============================================================
    //                    FUNCTIONS TO IMPLEMENT
    // ============================================================
    
    /* ========================= Liquidity Provider Functions =========================  */ 

    // Function addLiquidity: Adds liquidity given a supply of ETH (sent to the contract as msg.value).
    // You can change the inputs, or the scope of your function, as needed.
    function addLiquidity(uint maxExchangeRate, uint minExchangeRate) 
        external 
        payable
    {
       /******* TODO: Implement this function *******/
        require(msg.value > 0, "Must send ETH");// Require the user sends ETH
        uint ethAmount = msg.value; // Get the amount of ETH sent
        uint tokenAmount = (token_reserves * ethAmount) / eth_reserves;// Calculate the amount of tokens to send
        require(token.balanceOf(msg.sender) >= tokenAmount, "Insufficient tokens");// Require the user has enough tokens
        
        uint exchangeRate = (ethAmount * multiplier) / tokenAmount; // Calculate the exchange rate
        require(exchangeRate >= minExchangeRate, "Exchange rate too low");// Require the exchange rate is above the minimum
        require(exchangeRate <= maxExchangeRate, "Exchange rate too high");// Require the exchange rate is below the maximum
        token.transferFrom(msg.sender, address(this), tokenAmount); // Transfer the tokens to the contract
        uint lpShare = (total_shares * ethAmount) / eth_reserves; // Calculate the amount of shares to give to the user

        // Update the contract state
        lps[msg.sender] += lpShare;
        total_shares += lpShare; 
        eth_reserves += ethAmount;
        token_reserves += tokenAmount; 
        k = token_reserves * eth_reserves; // Update the constant k

        // emit LiquidityAdded(msg.sender, ethAmount, tokenAmount);
    }


    // Function removeLiquidity: Removes liquidity given the desired amount of ETH to remove.
    // You can change the inputs, or the scope of your function, as needed.
    function removeLiquidity(uint amountETH, uint maxExchangeRate, uint minExchangeRate)
        public 
        payable
    {
        /******* TODO: Implement this function *******/
        require(amountETH > 0, "Must specify an amount of ETH to remove");// Require the user specifies an amount of ETH to remove
        require(lps[msg.sender] > 0, "User is not a liquidity provider");// Require the user is a liquidity provider
        require(eth_reserves >= amountETH, "Insufficient ETH reserves");// Require the contract has enough ETH reserves

        uint share = (total_shares * amountETH) / eth_reserves; // Calculate the amount of shares the user is entitled to
        require(share <= lps[msg.sender], "Not enough liquidity owned"); // Require the user has enough shares
        
        uint tokenAmount = (token_reserves * amountETH) / eth_reserves; // Calculate the amount of tokens the user is entitled to
        uint exchangeRate = (eth_reserves * multiplier) / tokenAmount; // Calculate the exchange rate
        require(exchangeRate >= minExchangeRate, "Exchange rate too low");// Require the exchange rate is above the minimum
        require(exchangeRate <= maxExchangeRate, "Exchange rate too high");// Require the exchange rate is below the maximum
        require(token.balanceOf(address(this)) >= tokenAmount, "Insufficient tokens"); // Require the contract has enough tokens
        
        //Update the contract state
        lps[msg.sender] -= share;
        total_shares -= share;
        eth_reserves -= amountETH;
        token_reserves -= tokenAmount;
        
        // Transfer the tokens and ETH to the user
        token.transfer(msg.sender, tokenAmount);
        payable(msg.sender).transfer(amountETH);
        k = token_reserves * eth_reserves; // Update the constant k

        // emit LiquidityRemoved(msg.sender, amountETH, tokenAmount);
    }

    // Function removeAllLiquidity: Removes all liquidity that msg.sender is entitled to withdraw
    // You can change the inputs, or the scope of your function, as needed.
    function removeAllLiquidity(uint maxExchangeRate, uint minExchangeRate)
        external
        payable
    {
        /******* TODO: Implement this function *******/
        uint userShare = lps[msg.sender];// Get the amount of shares the user is entitled to
        require(userShare > 0, "No liquidity to remove");// Require the user has liquidity to remove
        
        uint exchangeRate = (eth_reserves * multiplier) / token_reserves; // Calculate the exchange rate
        require(exchangeRate >= minExchangeRate, "Exchange rate too low");// Require the exchange rate is above the minimum
        require(exchangeRate <= maxExchangeRate, "Exchange rate too high");// Require the exchange rate is below the maximum

        // Calculate the amount of ETH and tokens 
        uint ethAmount = (eth_reserves * userShare) / total_shares;
        uint tokenAmount = (token_reserves * userShare) / total_shares;
        
        // Require the contract has enough ETH and tokens
        require(eth_reserves - ethAmount >= 1, "Must leave at least 1 ETH in pool");
        require(token_reserves - tokenAmount >= 1, "Must leave at least 1 token in pool");

        // Update the contract state
        payable(msg.sender).transfer(ethAmount);
        token.transfer(msg.sender, tokenAmount);
        total_shares -= userShare;
        lps[msg.sender] = 0;
        eth_reserves -= ethAmount;
        token_reserves -= tokenAmount;
        }
    /***  Define additional functions for liquidity fees here as needed ***/


    /* ========================= Swap Functions =========================  */ 

    // Function swapTokensForETH: Swaps your token with ETH
    // You can change the inputs, or the scope of your function, as needed.
    function swapTokensForETH(uint amountTokens, uint maxSlippageRate)
        external 
        payable
    {
        /******* TODO: Implement this function *******/
        require(amountTokens > 0, "Must specify an amount of tokens to swap");// Require the user specifies an amount of tokens to swap
        require(token.balanceOf(msg.sender) >= amountTokens, "Insufficient tokens");// Require the user has enough tokens

        uint fee = (amountTokens * swap_fee_numerator) / swap_fee_denominator;
        uint tokenAmountAfterFee = amountTokens - fee;

        uint ethAmount = (eth_reserves * tokenAmountAfterFee) / token_reserves; // Calculate the amount of ETH the user is entitled to
        uint exchangeRate = (ethAmount * multiplier) / tokenAmountAfterFee; // Calculate the exchange rate
        require(exchangeRate <= maxSlippageRate, "Slippage rate too high");// Require the exchange rate is within the slippage rate
        require(eth_reserves - ethAmount >= 1, "Must leave at least 1 ETH in pool"); // Require the contract has enough ETH reserves

        // Update the contract state
        token.transferFrom(msg.sender, address(this), amountTokens);
        payable(msg.sender).transfer(ethAmount);
        token_reserves += tokenAmountAfterFee;
        eth_reserves -= ethAmount; 

        // emit Swap(msg.sender, msg.value, ethAmount, true);
    }



    // Function swapETHForTokens: Swaps ETH for your tokens
    // ETH is sent to contract as msg.value
    // You can change the inputs, or the scope of your function, as needed.
    function swapETHForTokens(uint maxSlippageRate)
        external
        payable 
    {
        /******* TODO: Implement this function *******/
        require(msg.value > 0, "Must send more than 0 ETH");// Require the user sends ETH

        uint fee = (msg.value * swap_fee_numerator) / swap_fee_denominator;
        uint ethAmountAfterFee = msg.value - fee;

        uint tokenAmount = (token_reserves * ethAmountAfterFee) / eth_reserves; // Calculate the amount of tokens the user is entitled to
        uint exchangeRate = (ethAmountAfterFee * multiplier) / tokenAmount; // Calculate the exchange rate
        require(exchangeRate <= maxSlippageRate, "Slippage rate too high");// Require the exchange rate is within the slippage rate
        require(token_reserves - tokenAmount >= 1, "Must leave at least 1 token in pool"); // Condition token

        token.transfer(msg.sender, tokenAmount); // Transfer the tokens to the user
        // Update the contract state
        token_reserves -= tokenAmount; 
        eth_reserves += ethAmountAfterFee;

        // emit Swap(msg.sender, msg.value, tokenAmount, true);
    }
}