// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IRebaseToken} from "./interfaces/IRebaseToken.sol";

contract Vault {
    // we need to pass the token address to the constructor
    // create a deposit function that mints tokens to the user equal to the amount of ETH the user has sent
    // create a redeem function that burns tokens from the user and sends the user ETH
    // create a way to add rewards to the vault
    error VAULT__RedeemFailed();

    IRebaseToken private immutable I_REBASE_TOKEN;

    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount); // indexed means “put this event field into the searchable log topics"

    constructor(IRebaseToken _rebaseToken) {
        I_REBASE_TOKEN = _rebaseToken;
    }

    receive() external payable {}

    /**
     * @notice Allows users to deposit ETH into the vault and mint rebase tokens in return
     */
    function deposit() external payable {
        // we need to use the amount of ETH the user has sent to mint tokens to the user
        uint256 interestRate = I_REBASE_TOKEN.getInterestRate();
        I_REBASE_TOKEN.mint(msg.sender, msg.value, interestRate);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Allows users to redeem their rebase tokens for ETH
     * @param _amount The amount of rebase tokens to redeem
     */
    function redeem(uint256 _amount) external {
        if (_amount == type(uint256).max) {
            _amount = I_REBASE_TOKEN.balanceOf(msg.sender);
        }
        // 1. burn the tokens from the user
        I_REBASE_TOKEN.burn(msg.sender, _amount);
        // 2. we need to send user ETH
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert VAULT__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    /**
     * @notice Get the address of the rebase token
     * @return The address of the rebase token
     */
    function getRebaseTokenAddress() external view returns (address) {
        return address(I_REBASE_TOKEN);
    }
}
