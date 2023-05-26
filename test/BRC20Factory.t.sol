// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/BRC20Factory.sol";


contract BRC20FactoryTest is Test {
    BRC20Factory public factory;
    BRC20 public brc20;

    uint256 internal signer0PrivKey = 0xAAAAA;
    uint256 internal signer1PrivKey = 0xBBBBB;
    uint256 internal signer2PrivKey = 0xCCCCC;
    uint256 internal signer3PrivKey = 0xDDDDD;

    uint256 internal ownerPrivateKey = 0xA11CE;
    uint256 internal spenderPrivateKey = 0xB0B;

    address internal owner; // 0xe05fcC23807536bEe418f142D19fa0d21BB0cfF7
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

        owner = vm.addr(ownerPrivateKey);
        to = vm.addr(spenderPrivateKey);

        factory = new BRC20Factory(signatures);

        address token = factory.createBRC20("ordi", "ordi", 18);
        brc20 = BRC20(token);
    }

    function testSigners() public {
        assertEq(factory.signers(0), signer0);
        assertEq(factory.authorized(signer0), true);
        assertEq(factory.indexes(signer0), 0);

        assertEq(factory.signers(1), signer1);
        assertEq(factory.authorized(signer1), true);
        assertEq(factory.indexes(signer1), 1);

        assertEq(factory.signers(2), signer2);
        assertEq(factory.authorized(signer2), true);
        assertEq(factory.indexes(signer2), 2);
    }

    function testSignatures() public {
        uint256 amount = 10000e18;
        string memory txid = "54d0d804f3a2caaf609d6c75c5fe71458f54a834f512c347a495012abf349990";

        bytes32 digest = factory.buildMintSeparator(address(brc20), to, amount, txid);

        (uint8 v0, bytes32 r0, bytes32 s0) = vm.sign(signer0PrivKey, digest);
        address _signer0 = ecrecover(digest, v0, r0, s0);
        assertEq(factory.authorized(_signer0), true);

        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(signer1PrivKey, digest);
        address _signer1 = ecrecover(digest, v1, r1, s1);
        assertEq(factory.authorized(_signer1), true);

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(signer2PrivKey, digest);
        address _signer2 = ecrecover(digest, v2, r2, s2);
        assertEq(factory.authorized(_signer2), true);
    }

    function testMint() public {
        uint256 amount = 10000e18;
        string memory txid = "54d0d804f3a2caaf609d6c75c5fe71458f54a834f512c347a495012abf349990";

        bytes32 digest = factory.buildMintSeparator(address(brc20), to, amount, txid);

        uint8[] memory vv = new uint8[](3);
        bytes32[] memory rr = new bytes32[](3);
        bytes32[] memory ss = new bytes32[](3);
        (vv[0], rr[0], ss[0]) = vm.sign(signer0PrivKey, digest);
        (vv[1], rr[1], ss[1]) = vm.sign(signer1PrivKey, digest);
        (vv[2], rr[2], ss[2]) = vm.sign(signer2PrivKey, digest);

        factory.mint(address(brc20), to, amount, txid, vv, rr, ss);
        assertEq(brc20.balanceOf(to), amount);

        vm.startPrank(to);
        brc20.transfer(owner, amount);
        assertEq(brc20.balanceOf(to), 0);
        assertEq(brc20.balanceOf(owner), amount);
        vm.stopPrank();

        vm.startPrank(owner);
        brc20.approve(address(factory), amount);
        vm.deal(owner, 1 ether);
        factory.burn{value: 0.01 ether}(address(brc20), amount, txid);
        assertEq(brc20.balanceOf(owner), 0);
        vm.stopPrank();
    }

    function testAddSigner() public {
        factory.addSigner(signer3);
        assertEq(factory.signers(3), signer3);
        assertEq(factory.authorized(signer3), true);
        assertEq(factory.indexes(signer3), 3);

        factory.removeSigner(signer1);
        assertEq(factory.authorized(signer1), false);
        assertEq(factory.signers(1), signer3);
        assertEq(factory.indexes(signer3), 1);

    }

    function testOwner() public {
        assertEq(factory.owner(), address(this));
        factory.setOwner(owner);
        assertEq(factory.owner(), owner);
    }
    
    function testFee() public {
        assertEq(factory.fee(), 0.01 ether);
        factory.setFee(0.02 ether);
        assertEq(factory.fee(), 0.02 ether);
    }

    function testTransfer() public {
        deal(address(brc20), to, 10000e18);
        assertEq(brc20.balanceOf(to), 10000e18);
    }

}