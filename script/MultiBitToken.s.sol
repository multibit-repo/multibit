// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/MultiBitToken.sol";


contract MultiBitTokenScript is Script {
    
    MultiBitToken public token;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        token = new MultiBitToken();
        vm.stopBroadcast();
    }
}
