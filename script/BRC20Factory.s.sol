// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/BRC20Factory.sol";


contract BRC20FactoryScript is Script {
    
    BRC20Factory public factory;

    address[] signers = [
        0xA88d7a664Ff04d0324D4c3f991ee6b172098c81A,
        0xd1A0445b0b873b764Fd3d850c07463fC97d77832,
        0x16202F80a377F2290D046C9bA5EFDc295B22B1Dc
    ];

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        factory = new BRC20Factory(signers);
        factory.createBRC20("xxx", "xxx", 18);
        vm.stopBroadcast();
    }
}
