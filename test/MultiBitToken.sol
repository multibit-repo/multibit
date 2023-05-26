// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MultiBitToken.sol";


contract MultiBitTokenTest is Test {
    MultiBitToken public token;

    function setUp() public {
        token = new MultiBitToken();
    }

    function testMint() public {
        assertEq(token.balanceOf(address(this)), 100000000e18);
    }

    function testBurn() public {
        token.burn(100000000e18);
        assertEq(token.balanceOf(address(this)), 0);
    }
}
