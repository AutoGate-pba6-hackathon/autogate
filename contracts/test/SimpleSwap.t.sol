// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

// Import the contract to test
import {SimpleSwap} from "../src/SimpleSwap.sol";

// Import or define a mock ERC20 for testing
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// For simplicity in this example, let's define a basic Mock ERC20 here
contract MockERC20 is IERC20 {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    uint256 public _totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        allowances[sender][msg.sender] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(address to, uint256 amount) external {
        balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}

contract SimpleSwapTest is Test {
    SimpleSwap public simpleSwap;
    MockERC20 public tokenA; // Our token0
    MockERC20 public tokenB; // Our token1

    // Define some addresses for testing using Foundry's cheatcodes
    address public user = address(0x1); // A regular user wanting to swap
    address public lp = address(0x2); // A liquidity provider (for setup)
    address public swapContractAddress;

    // Helper constants for amounts (makes tests readable)
    uint256 constant INITIAL_LP_A = 1000 * 1 ether; // 1000 Token A
    uint256 constant INITIAL_LP_B = 500 * 1 ether; // 500 Token B (initial price: 1 A = 0.5 B)
    uint256 constant USER_INITIAL_A = 100 * 1 ether; // User starts with 100 Token A

    function setUp() public {
        // Deploy Mock Tokens
        tokenA = new MockERC20("Token A", "TKNA", 18);
        tokenB = new MockERC20("Token B", "TKNB", 18);

        // Deploy SimpleSwap contract with the token addresses
        simpleSwap = new SimpleSwap(address(tokenA), address(tokenB));
        swapContractAddress = address(simpleSwap);

        // --- Provide Initial Liquidity ---
        // Mint tokens to the LP address
        tokenA.mint(lp, INITIAL_LP_A);
        tokenB.mint(lp, INITIAL_LP_B);

        // Directly transfer initial liquidity from LP to the swap contract
        // This simulates adding liquidity without an addLiquidity function
        vm.startPrank(lp);
        tokenA.transfer(swapContractAddress, INITIAL_LP_A);
        tokenB.transfer(swapContractAddress, INITIAL_LP_B);
        vm.stopPrank();

        // --- Prepare User ---
        // Mint some Token A for the user
        tokenA.mint(user, USER_INITIAL_A);

        // User needs to approve the swap contract to spend their Token A
        vm.startPrank(user);
        tokenA.approve(swapContractAddress, type(uint256).max); // Approve max amount
        vm.stopPrank();

        console.log("--- Setup Complete ---");
        console.log(
            "Initial Pool Reserves: A=%s, B=%s",
            INITIAL_LP_A,
            INITIAL_LP_B
        );
        console.log(
            "User Initial Balance: A=%s, B=%s",
            tokenA.balanceOf(user),
            tokenB.balanceOf(user)
        );
    }

    // Test swapping Token A (token0) for Token B (token1)
    function testSwapToken0ForToken1() public {
        uint256 amountInA = 10 * 1 ether; // User wants to swap 10 Token A

        // --- Calculate Expected Output (mirroring contract logic) ---
        uint256 reserveA = tokenA.balanceOf(swapContractAddress); // Should be INITIAL_LP_A
        uint256 reserveB = tokenB.balanceOf(swapContractAddress); // Should be INITIAL_LP_B

        uint256 amountInWithFee = (amountInA * 997) / 1000;
        uint256 numerator = amountInWithFee * reserveB;
        uint256 denominator = reserveA + amountInWithFee;
        uint256 expectedAmountOutB = numerator / denominator;

        console.log("Test: Swapping %s Token A", amountInA);
        console.log("Expected output Token B: %s", expectedAmountOutB);

        // --- Balances Before Swap ---
        uint256 userBalanceABefore = tokenA.balanceOf(user);
        uint256 userBalanceBBefore = tokenB.balanceOf(user);
        uint256 poolBalanceABefore = tokenA.balanceOf(swapContractAddress);
        uint256 poolBalanceBBefore = tokenB.balanceOf(swapContractAddress);

        // --- Perform Swap (as the user) ---
        vm.startPrank(user);
        simpleSwap.swapToken0ForToken1(amountInA, user); // Send output B to the user
        vm.stopPrank();

        // --- Balances After Swap ---
        uint256 userBalanceAAfter = tokenA.balanceOf(user);
        uint256 userBalanceBAfter = tokenB.balanceOf(user);
        uint256 poolBalanceAAfter = tokenA.balanceOf(swapContractAddress);
        uint256 poolBalanceBAfter = tokenB.balanceOf(swapContractAddress);

        console.log("--- Balances After Swap ---");
        console.log(
            "User Balance: A=%s, B=%s",
            userBalanceAAfter,
            userBalanceBAfter
        );
        console.log(
            "Pool Balance: A=%s, B=%s",
            poolBalanceAAfter,
            poolBalanceBAfter
        );

        // --- Assertions ---
        // User's Token A balance should decrease by amountInA
        assertEq(
            userBalanceAAfter,
            userBalanceABefore - amountInA,
            "User Token A balance mismatch"
        );
        // User's Token B balance should increase by expectedAmountOutB
        assertEq(
            userBalanceBAfter,
            userBalanceBBefore + expectedAmountOutB,
            "User Token B balance mismatch"
        );
        // Pool's Token A balance should increase by amountInA
        assertEq(
            poolBalanceAAfter,
            poolBalanceABefore + amountInA,
            "Pool Token A balance mismatch"
        );
        // Pool's Token B balance should decrease by expectedAmountOutB
        assertEq(
            poolBalanceBAfter,
            poolBalanceBBefore - expectedAmountOutB,
            "Pool Token B balance mismatch"
        );

        // Check constant product invariant (approximately, due to fees and integer math)
        // uint kBefore = poolBalanceABefore * poolBalanceBBefore;
        // uint kAfter = poolBalanceAAfter * poolBalanceBAfter;
        // console.log("k Before: %s", kBefore);
        // console.log("k After: %s", kAfter);
        // assertGe(kAfter, kBefore); // k should increase slightly due to the fee retaining value in the pool
    }

    // You can add a similar test `testSwapToken1ForToken0` here
}
