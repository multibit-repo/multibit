// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Vault.sol";
import "../src/MultiBitToken.sol";

contract VaultTest is Test {
    Vault public vault;
    MultiBitToken public token;

    uint256 internal signer0PrivKey = 0xAAAAA;
    uint256 internal signer1PrivKey = 0xBBBBB;
    uint256 internal signer2PrivKey = 0xCCCCC;
    uint256 internal signer3PrivKey = 0xDDDDD;

    uint256 internal adminPrivateKey = 0xA11CE;
    uint256 internal spenderPrivateKey = 0xB0B;

    address internal admin; // 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7
    address internal to; // 0x0376AAc07Ad725E01357B1725B5ceC61aE10473c

    address internal signer0; // 0x84360CE97D89Da9ADadAeC87d0A3769c9A266dA5
    address internal signer1; // 0x9A91384973BB8c64627b52AE5a9643839fB8092B
    address internal signer2; // 0xEc908bf34F5949F7eaA02E9479605152D1fb4D26
    address internal signer3;

    address[] public signatures;

    function setUp() public {
        signer0 = vm.addr(signer0PrivKey);
        signer1 = vm.addr(signer1PrivKey);
        signer2 = vm.addr(signer2PrivKey);
        signer3 = vm.addr(signer3PrivKey);

        signatures.push(signer0);
        signatures.push(signer1);
        signatures.push(signer2);

        admin = vm.addr(adminPrivateKey);
        to = vm.addr(spenderPrivateKey);

        vault = new Vault(signatures);

        token = new MultiBitToken();
    }

    function testSigners() public {
        assertEq(vault.signers(0), signer0);
        assertEq(vault.authorized(signer0), true);
        assertEq(vault.indexes(signer0), 0);

        assertEq(vault.signers(1), signer1);
        assertEq(vault.authorized(signer1), true);
        assertEq(vault.indexes(signer1), 1);

        assertEq(vault.signers(2), signer2);
        assertEq(vault.authorized(signer2), true);
        assertEq(vault.indexes(signer2), 2);
    }

    function testSignatures() public {
        uint256 amount = 10000e18;
        string memory txid = "54d0d804f3a2caaf609d6c75c5fe71458f54a834f512c347a495012abf349990";

        bytes32 digest = vault.buildMintSeparator(address(token), to, amount, txid);

        (uint8 v0, bytes32 r0, bytes32 s0) = vm.sign(signer0PrivKey, digest);
        address _signer0 = ecrecover(digest, v0, r0, s0);
        assertEq(vault.authorized(_signer0), true);

        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(signer1PrivKey, digest);
        address _signer1 = ecrecover(digest, v1, r1, s1);
        assertEq(vault.authorized(_signer1), true);

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(signer2PrivKey, digest);
        address _signer2 = ecrecover(digest, v2, r2, s2);
        assertEq(vault.authorized(_signer2), true);
    }

    function testDeposit() public {
        uint256 amount = 10000e18;
        string memory receiver = "bc1pye7x2acklkejlx8avyzzzxkz7zfse6w0ekf4389ftt2f3krljtts26unl2";

        if (token.approve(address(vault), amount)) {
            vault.deposit{value: 0.01 ether}(address(token), amount, receiver);
        }
        
        assertEq(token.balanceOf(address(vault)), amount);

        // vault.deposit{value: 0.01 ether}(address(0), 1 ether, "");
        // vm.expectRevert("invalid receiver");
    }

    function testWithdrawETH() public {
        uint256 amount = 1 ether;
        string memory txid = "54d0d804f3a2caaf609d6c75c5fe71458f54a834f512c347a495012abf349990";

        bytes32 digest = vault.buildMintSeparator(address(0), to, amount, txid);

        uint8[] memory vv = new uint8[](3);
        bytes32[] memory rr = new bytes32[](3);
        bytes32[] memory ss = new bytes32[](3);
        (vv[0], rr[0], ss[0]) = vm.sign(signer0PrivKey, digest);
        (vv[1], rr[1], ss[1]) = vm.sign(signer1PrivKey, digest);
        (vv[2], rr[2], ss[2]) = vm.sign(signer2PrivKey, digest);

        vm.deal(address(vault), 1 ether);

        vault.approve(address(0), amount);
        assertEq(vault.allowances(address(0)), amount);

        vault.withdraw(address(0), to, amount, txid, vv, rr, ss);

        assertEq(address(vault).balance, 0);
    }

    function testWithdrawERC20() public {
        uint256 amount = 10000e18;
        string memory txid = "54d0d804f3a2caaf609d6c75c5fe71458f54a834f512c347a495012abf349990";

        bytes32 digest = vault.buildMintSeparator(address(token), to, amount, txid);

        uint8[] memory vv = new uint8[](3);
        bytes32[] memory rr = new bytes32[](3);
        bytes32[] memory ss = new bytes32[](3);
        (vv[0], rr[0], ss[0]) = vm.sign(signer0PrivKey, digest);
        (vv[1], rr[1], ss[1]) = vm.sign(signer1PrivKey, digest);
        (vv[2], rr[2], ss[2]) = vm.sign(signer2PrivKey, digest);

        token.transfer(address(vault), amount);

        assertEq(token.balanceOf(address(vault)), amount);

        vault.approve(address(token), amount);
        assertEq(vault.allowances(address(token)), amount);

        vault.withdraw(address(token), to, amount, txid, vv, rr, ss);

        assertEq(token.balanceOf(address(vault)), 0);
    }

    function testAddSigner() public {
        vault.addSigner(signer3);
        assertEq(vault.signers(3), signer3);
        assertEq(vault.authorized(signer3), true);
        assertEq(vault.indexes(signer3), 3);

        vault.removeSigner(signer1);
        assertEq(vault.authorized(signer1), false);
        assertEq(vault.signers(1), signer3);
        assertEq(vault.indexes(signer3), 1);

    }

    function testAdmin() public {
        assertEq(vault.admin(), address(this));

        vault.setPendingAdmin(to);

        assertEq(vault.pendingAdmin(), to);

        vm.startPrank(to);

        vault.acceptAdmin();

        assertEq(vault.pendingAdmin(), address(0));
        assertEq(vault.admin(), to);

        vm.stopPrank();
    }
    
    function testFee() public {
        assertEq(vault.fee(), 0.01 ether);
        vault.setFee(0.02 ether);
        assertEq(vault.fee(), 0.02 ether);
    }

    function testApprove() public {
        vault.approve(address(0), 10 ether);
        assertEq(vault.allowances(address(0)), 10 ether);
    }

    function testWithdrawFees() public {
        string memory receiver = "bc1pye7x2acklkejlx8avyzzzxkz7zfse6w0ekf4389ftt2f3krljtts26unl2";

        vault.deposit{value: 1.01 ether}(address(0), 1 ether, receiver);
        vault.deposit{value: 1.01 ether}(address(0), 1 ether, receiver);
        vault.deposit{value: 1.01 ether}(address(0), 1 ether, receiver);
        
        assertEq(vault.totalFees(), 0.03 ether);

        vault.withdrawFees(to);

        assertEq(vault.totalFees(), 0);
    }

}