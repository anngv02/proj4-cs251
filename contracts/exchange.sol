// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./token.sol";
import "hardhat/console.sol";

contract TokenExchange is Ownable {
    string public exchange_name = "";

    address tokenAddr = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
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

    // For use with exchange rates
    uint private multiplier = 10 ** 5;

    uint private ten_to_eighteen = 10 ** 18;

    constructor() {}

    // Function createPool: Initializes a liquidity pool between your Token and ETH.
    // ETH will be sent to pool in this transaction as msg.value
    // amountTokens specifies the amount of tokens to transfer from the liquidity provider.
    // Sets up the initial exchange rate for the pool by setting amount of token and amount of ETH.
    function createPool(uint amountTokens) external payable onlyOwner {
        // This function is already implemented for you; no changes needed.

        // require pool does not yet exist:
        require(token_reserves == 0, "Token reserves was not 0");
        require(eth_reserves == 0, "ETH reserves was not 0.");

        // require nonzero values were sent
        require(msg.value > 0, "Need eth to create pool.");
        uint tokenSupply = token.balanceOf(msg.sender);
        require(
            amountTokens <= tokenSupply,
            "Not have enough tokens to create the pool"
        );
        require(amountTokens > 0, "Need tokens to create pool.");
        token.transferFrom(msg.sender, address(this), amountTokens);
        token_reserves = token.balanceOf(address(this));
        eth_reserves = msg.value;
        k = token_reserves * eth_reserves;

        // Pool shares set to a large value to minimize round-off errors
        total_shares = 10 ** 5;
        // Pool creator has some low amount of shares to allow autograder to run
        lps[msg.sender] = 100;
    }

    // For use for ExtraCredit ONLY
    // Function removeLP: removes a liquidity provider from the list.
    // This function also removes the gap left over from simply running "delete".
    function removeLP(uint index) private {
        require(
            index < lp_providers.length,
            "specified index is larger than the number of lps"
        );
        lp_providers[index] = lp_providers[lp_providers.length - 1];
        lp_providers.pop();
    }

    // Function getSwapFee: Returns the current swap fee ratio to the client.
    function getSwapFee() public view returns (uint, uint) {
        return (swap_fee_numerator, swap_fee_denominator);
    }

    // ============================================================
    //                    FUNCTIONS TO IMPLEMENT
    // ============================================================
    function calcDeltaToken(uint delta_eth) private view returns (uint) {
        // delta eth is in wei
        uint delta_token = (token.balanceOf(address(this)) * delta_eth) /
            (address(this).balance);
        return delta_token;
    }

    /* ========================= Liquidity Provider Functions =========================  */

    function addLiquidity(uint maxExchangeRate, uint minExchangeRate) 
        external 
        payable
    {
       /******* TODO: Implement this function *******/
        require(msg.value > 0, "Must send ETH");// Require the user sends ETH
        uint denta_token = calcDeltaToken(msg.value);// Calculate the amount of tokens to send
        require(token.balanceOf(msg.sender) >= denta_token, "Insufficient tokens");// Require the user has enough tokens
        
        uint exchangeRate = (token_reserves * multiplier * ten_to_eighteen) / eth_reserves; // Calculate the exchange rate
        require(exchangeRate >= minExchangeRate, "Exchange rate too low");// Require the exchange rate is above the minimum
        require(exchangeRate <= maxExchangeRate, "Exchange rate too high");// Require the exchange rate is below the maximum
        token.transferFrom(msg.sender, address(this), denta_token); // Transfer the tokens to the contract
        uint share = (total_shares * msg.value) / eth_reserves; // Calculate the amount of shares to give to the user

        // Update the contract state
        lps[msg.sender] += share;
        total_shares += share; 
        eth_reserves += msg.value;
        token_reserves += denta_token;
        k = token_reserves * eth_reserves; // Update the constant k
    }

    function removeLiquidity(uint amountETH, uint maxExchangeRate, uint minExchangeRate)
        public 
        payable
    {
        /******* TODO: Implement this function *******/
        require(amountETH > 0, "Must specify an amount of ETH to remove");// Require the user specifies an amount of ETH to remove
        require(eth_reserves - 1 >= amountETH, "Insufficient ETH reserves");// Require the contract has enough ETH reserves

        uint share = (amountETH * total_shares) / eth_reserves;
        total_shares -= share;
        require(
            lps[msg.sender] >= share,
            "LP does not have enough shares to remove the inputted amount of liquidity."
        );

        uint denta_token = calcDeltaToken(amountETH); // Calculate the amount of tokens the user is entitled to
        uint exchangeRate = (token_reserves * multiplier * ten_to_eighteen) / eth_reserves; // Calculate the exchange rate
        require(exchangeRate >= minExchangeRate, "Exchange rate too low");// Require the exchange rate is above the minimum
        require(exchangeRate <= maxExchangeRate, "Exchange rate too high");// Require the exchange rate is below the maximum
        require(token.balanceOf(address(this)) >= denta_token, "Insufficient tokens"); // Require the contract has enough tokens
        
        // Calculate the benefit for the user   
        uint diff_eth = address(this).balance - eth_reserves;
        uint diff_token = token.balanceOf(address(this)) - token_reserves;
        uint benefit_eth = (diff_eth * share) / total_shares;
        uint benefit_token = (diff_token * share) / total_shares;

        lps[msg.sender] -= share; // Update the user's share
        eth_reserves -= amountETH;
        token_reserves -= denta_token;
        
        k = token_reserves * eth_reserves; // Update the constant k

        // Transfer the tokens and ETH to the user
        token.transfer(msg.sender, denta_token + benefit_token);
        payable(msg.sender).transfer( amountETH + benefit_eth);
    }

    // Function removeAllLiquidity: Removes all liquidity that msg.sender is entitled to withdraw
    // You can change the inputs, or the scope of your function, as needed.
        function removeAllLiquidity(uint maxExchangeRate, uint minExchangeRate)
        external
        payable
    {
        /******* TODO: Implement this function *******/
        uint shareCall = lps[msg.sender];
        uint ethCall = (shareCall * eth_reserves) / total_shares;
        removeLiquidity(ethCall, maxExchangeRate, minExchangeRate);
    }
    /***  Define additional functions for liquidity fees here as needed ***/

    /* ========================= Swap Functions =========================  */

    // Function swapTokensForETH: Swaps your token with ETH
    // You can change the inputs, or the scope of your function, as needed.
    function swapTokensForETH(
        uint amountTokens,
        uint maxSlippageRate
    ) external payable {
        // Check that caller has enough tokens to make swap of this size
        uint callerSupply = token.balanceOf(msg.sender);
        require(
            amountTokens <= callerSupply,
            "Caller does not have enough tokens to make swap"
        );
        uint fee_adjusted_amountTokens = amountTokens -
            (amountTokens * swap_fee_numerator) /
            swap_fee_denominator;
        uint new_token_reserves = token_reserves + fee_adjusted_amountTokens;
        uint new_eth_reserves = k / new_token_reserves;
        uint amountEth = eth_reserves - new_eth_reserves;

        // Check slippage
        require((token_reserves * multiplier * ten_to_eighteen) / eth_reserves < maxSlippageRate, "Failed due to slippage");
        require( amountEth <= (eth_reserves - 1), "Swap failed due to prevention of Eth supply dipping below 1");

        eth_reserves = new_eth_reserves;
        token_reserves = new_token_reserves;

        // transfer eth to sender
        payable(msg.sender).transfer(amountEth);
        // transfer tokens from sender to contract
        token.transferFrom(msg.sender, address(this), amountTokens);
    }
    // Function swapETHForTokens: Swaps ETH for your tokens
    // ETH is sent to contract as msg.value
    // You can change the inputs, or the scope of your function, as needed.
    function swapETHForTokens(uint maxSlippageRate) external payable {
        uint fee_after_amountEth = msg.value - (msg.value * swap_fee_numerator) / swap_fee_denominator;
        uint new_eth_reserves = eth_reserves + fee_after_amountEth;
        uint new_token_reserves = k / new_eth_reserves;
        uint amountToken = token_reserves - new_token_reserves;

        // Check slippage
        require( (eth_reserves * multiplier) / (token_reserves * ten_to_eighteen) < maxSlippageRate, "Failed due to slippage");

        require( amountToken <= (token_reserves - 1), "Swap failed due to prevention of Token supply dipping below 1");

        eth_reserves = new_eth_reserves;
        token_reserves = new_token_reserves;
        bool worked = token.transfer(msg.sender, amountToken);
        require(worked, "Token transfer failed");
    }
}
