// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SimpleSwap
 * @notice Basic AMM DEX for two ERC20 tokens with an allowlist for swappers.
 * Inherits Ownable to manage allowlist access.
 */
contract SimpleSwap is Ownable {
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    // --- Allowlist State ---
    mapping(address => bool) public isAllowed;

    // --- Events ---
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );

    event AllowedAddressAdded(address indexed account);
    event AllowedAddressRemoved(address indexed account);

    // --- Constructor ---
    constructor(address _token0, address _token1) Ownable(msg.sender) {
        require(
            _token0 != address(0) && _token1 != address(0),
            "SimpleSwap: ZERO_ADDRESS"
        );
        require(_token0 != _token1, "SimpleSwap: IDENTICAL_ADDRESSES");
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    // --- Allowlist Management (Only Owner) ---

    /**
     * @notice Add an address to the swap allowlist.
     * @param _account The address to allow.
     * @dev Can only be called by the owner.
     */
    function addAllowedAddress(address _account) external onlyOwner {
        require(_account != address(0), "SimpleSwap: ZERO_ADDRESS");
        require(!isAllowed[_account], "SimpleSwap: Address already allowed");
        isAllowed[_account] = true;
        emit AllowedAddressAdded(_account);
    }

    /**
     * @notice Remove an address from the swap allowlist.
     * @param _account The address to remove.
     * @dev Can only be called by the owner.
     */
    function removeAllowedAddress(address _account) external onlyOwner {
        require(_account != address(0), "SimpleSwap: ZERO_ADDRESS");
        require(
            isAllowed[_account],
            "SimpleSwap: Address not currently allowed"
        );
        isAllowed[_account] = false;
        emit AllowedAddressRemoved(_account);
    }

    // --- Swap Functions ---

    /**
     * @notice Swaps an exact amount of token0 for as much token1 as possible.
     * @param amount0In The exact amount of token0 to send.
     * @param to The address to receive the output token1.
     * @dev Caller (msg.sender) must be on the allowlist.
     * @dev User must have approved this contract to spend `amount0In` of token0.
     */
    function swapToken0ForToken1(uint amount0In, address to) external {
        require(isAllowed[msg.sender], "SimpleSwap: Caller not allowed");

        require(amount0In > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(to != address(0), "SimpleSwap: INVALID_RECIPIENT");

        uint currentReserve0 = token0.balanceOf(address(this));
        uint currentReserve1 = token1.balanceOf(address(this));
        require(
            currentReserve0 > 0 && currentReserve1 > 0,
            "SimpleSwap: INSUFFICIENT_LIQUIDITY"
        );

        token0.transferFrom(msg.sender, address(this), amount0In);

        uint amountInWithFee = (amount0In * 997) / 1000;
        uint numerator = amountInWithFee * currentReserve1;
        uint denominator = currentReserve0 + amountInWithFee;
        uint amount1Out = numerator / denominator;

        require(amount1Out > 0, "SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            token1.balanceOf(address(this)) >= amount1Out,
            "SimpleSwap: INSUFFICIENT_POOL_BALANCE"
        );

        token1.transfer(to, amount1Out);

        emit Swap(msg.sender, amount0In, 0, 0, amount1Out, to);
    }

    /**
     * @notice Swaps an exact amount of token1 for as much token0 as possible.
     * @param amount1In The exact amount of token1 to send.
     * @param to The address to receive the output token0.
     * @dev Caller (msg.sender) must be on the allowlist.
     * @dev User must have approved this contract to spend `amount1In` of token1.
     */
    function swapToken1ForToken0(uint amount1In, address to) external {
        require(isAllowed[msg.sender], "SimpleSwap: Caller not allowed");

        require(amount1In > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(to != address(0), "SimpleSwap: INVALID_RECIPIENT");

        uint currentReserve0 = token0.balanceOf(address(this));
        uint currentReserve1 = token1.balanceOf(address(this));
        require(
            currentReserve0 > 0 && currentReserve1 > 0,
            "SimpleSwap: INSUFFICIENT_LIQUIDITY"
        );

        token1.transferFrom(msg.sender, address(this), amount1In);

        uint amountInWithFee = (amount1In * 997) / 1000;
        uint numerator = amountInWithFee * currentReserve0;
        uint denominator = currentReserve1 + amountInWithFee;
        uint amount0Out = numerator / denominator;

        require(amount0Out > 0, "SimpleSwap: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            token0.balanceOf(address(this)) >= amount0Out,
            "SimpleSwap: INSUFFICIENT_POOL_BALANCE"
        );

        token0.transfer(to, amount0Out);

        emit Swap(msg.sender, 0, amount1In, amount0Out, 0, to);
    }

    // --- Helper/View Functions (Unchanged) ---
    function getReserves() public view returns (uint reserve0, uint reserve1) {
        reserve0 = token0.balanceOf(address(this));
        reserve1 = token1.balanceOf(address(this));
    }

    function getAmountOut(
        uint _amountIn,
        address _inputToken
    ) public view returns (uint amountOut) {
        require(
            _inputToken == address(token0) || _inputToken == address(token1),
            "SimpleSwap: INVALID_TOKEN"
        );

        uint reserveIn;
        uint reserveOut;
        if (_inputToken == address(token0)) {
            (reserveIn, reserveOut) = getReserves();
        } else {
            (reserveOut, reserveIn) = getReserves();
        }

        require(
            reserveIn > 0 && reserveOut > 0,
            "SimpleSwap: INSUFFICIENT_LIQUIDITY"
        );
        require(_amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");

        uint amountInWithFee = (_amountIn * 997) / 1000;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
