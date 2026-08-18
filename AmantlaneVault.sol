// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title AmantlaneVault
 * @author Amantlane core engineering
 * @notice Gas-optimized ERC-4626 minimalist staking vault with strict Reentrancy protection.
 */
contract AmantlaneVault is ReentrancyGuard {
    using SafeERC20 for IERC20;

    error ZeroDeposit();
    error ZeroShares();
    error InsufficientBalance();

    IERC20 public immutable asset;
    
    uint256 public totalShares;
    uint256 public totalAssets;

    mapping(address => uint256) public balanceOf;

    constructor(address _asset) {
        asset = IERC20(_asset);
    }

    /**
     * @notice Deposits underlying assets to mint proportional vault pool shares.
     */
    function deposit(uint256 _amount) external nonReentrant {
        if (_amount == 0) revert ZeroDeposit();

        uint256 _shares;
        if (totalShares == 0) {
            _shares = _amount;
        } else {
            _shares = (_amount * totalShares) / totalAssets;
        }

        if (_shares == 0) revert ZeroShares();

        totalAssets += _amount;
        totalShares += _shares;
        balanceOf[msg.sender] += _shares;

        asset.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Redeems vault pool shares to withdraw underlying assets.
     */
    function withdraw(uint256 _shares) external nonReentrant {
        if (_shares == 0) revert ZeroShares();
        if (balanceOf[msg.sender] < _shares) revert InsufficientBalance();

        uint256 _amount = (_shares * totalAssets) / totalShares;
        
        totalShares -= _shares;
        totalAssets -= _amount;
        balanceOf[msg.sender] -= _shares;

        asset.safeTransfer(msg.sender, _amount);
    }
}
