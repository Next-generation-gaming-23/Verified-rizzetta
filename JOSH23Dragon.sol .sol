// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/// @title Joshua Nguyen 23 (JOSH23) — "Dragon" version (self-contained, fixed-fee)
/// @notice Zero external imports. 1B fixed supply minted once to FEE_RECIPIENT.
///         5% fee on every transfer, paid to FEE_RECIPIENT. Transfers FROM the
///         fee recipient are exempt (distribution / liquidity seeding is fee-free).
///         Fee rate and recipient are immutable: no owner, no setters, no minting,
///         no upgrades, no proxy. Nobody — not even the deployer — can ever
///         change this contract's rules or touch anyone's balance.
contract JOSH23Dragon {
    string public constant name = "Joshua Nguyen 23";
    string public constant symbol = "JOSH23";
    uint8 public constant decimals = 18;

    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 * 10 ** 18;
    uint256 public constant FEE_BPS = 500; // 5% — fixed forever
    uint256 public constant BPS_DENOMINATOR = 10_000;

    address public immutable FEE_RECIPIENT;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(address feeRecipient) {
        require(feeRecipient != address(0), "JOSH23: zero fee recipient");
        FEE_RECIPIENT = feeRecipient;
        totalSupply = TOTAL_SUPPLY;
        balanceOf[feeRecipient] = TOTAL_SUPPLY;
        emit Transfer(address(0), feeRecipient, TOTAL_SUPPLY);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= value, "JOSH23: insufficient allowance");
        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0), "JOSH23: transfer to zero address");
        uint256 fee = 0;
        if (from != FEE_RECIPIENT) {
            fee = (value * FEE_BPS) / BPS_DENOMINATOR;
        }
        require(balanceOf[from] >= value, "JOSH23: insufficient balance");
        unchecked {
            balanceOf[from] -= value;
            balanceOf[to] += value - fee;
            if (fee > 0) {
                balanceOf[FEE_RECIPIENT] += fee;
                emit Transfer(from, FEE_RECIPIENT, fee);
            }
        }
        emit Transfer(from, to, value - fee);
    }
}
