// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "../src/IRepositoryIndex.sol";
import "../src/RepositoryIndex.sol";

contract RepositoryIndexTest is Test, IRepositoryIndexEvents {
    RepositoryIndex repo;

    address alice;
    address bob;

    string group;
    uint256 groupId;

    function setUp() public {
        repo = new RepositoryIndex();

        alice = address(1234);
        bob = address(2345);

        group = "default-group";
        groupId = uint256(keccak256(abi.encodePacked(group)));
    }

    function testRegister() public {
        string memory name = "hello-world";

        uint256 tokenId = uint256(keccak256(abi.encodePacked(name)));

        vm.expectEmit(true, true, true, true);
        emit GroupCreated(alice, tokenId, name);

        vm.prank(alice);
        uint256 resultId = repo.register(name);

        assertEq(resultId, tokenId);
        assertEq(repo.balanceOf(alice), 1);
    }

    function testRegister_duplicate() public {
        string memory name = "hello-world";

        uint256 tokenId = uint256(keccak256(abi.encodePacked(name)));

        vm.expectEmit(true, true, true, true);
        emit GroupCreated(alice, tokenId, name);

        vm.prank(alice);
        repo.register(name);

        // catch 2nd attempt to register a new group
        vm.prank(alice);
        vm.expectRevert("ERC721: token already minted");
        repo.register(name);
    }

    function testCreateRelease() public {
        vm.startPrank(alice);
        repo.register(group);

        string memory packageName = "my-package";
        string memory version = "1.0.0";

        createRelease(packageName, version);
    }

    function createRelease(string memory packageName, string memory version)
        internal
    {
        string[] memory content = new string[](1);
        content[0] = "some data";

        vm.expectEmit(true, true, true, true);
        emit ReleaseCreated(groupId, packageName, version, alice);

        repo.release(groupId, packageName, version, content);

        (bool exists, string[] memory content_, bool nuked) = repo.getRelease(
            group,
            packageName,
            version
        );

        assertTrue(exists);
        assertEq(content_.length, 1);
        assertEq(content_[0], content[0]);
        assertFalse(nuked);
    }

    function testCreateRelease_noContent() public {
        vm.startPrank(alice);
        repo.register(group);

        string memory packageName = "my-package";
        string memory version = "1.0.0";
        string[] memory content = new string[](0);

        vm.expectRevert("no content provided");
        repo.release(groupId, packageName, version, content);
    }

    function testCreateRelease_notOwner() public {
        vm.prank(alice);
        repo.register(group);

        // bob tries to release a package in a group he does not own
        vm.startPrank(bob);
        string memory packageName = "my-package";
        string memory version = "1.0.0";
        string[] memory content = new string[](1);
        content[0] = "some data";

        vm.expectRevert("not owner of group");
        repo.release(groupId, packageName, version, content);
    }

    function testCreateRelease_inValidName() public {
        vm.startPrank(alice);
        repo.register(group);

        string memory packageName = "my-pac  kage";
        string memory version = "1.0.0";
        string[] memory content = new string[](1);
        content[0] = "some data";

        vm.expectRevert("not a valid name");
        repo.release(groupId, packageName, version, content);
    }

    function testCreateRelease_inValidVersion() public {
        vm.startPrank(alice);
        repo.register(group);

        string memory packageName = "my-package";
        string memory version = "x1.0.a 0";
        string[] memory content = new string[](1);
        content[0] = "some data";

        vm.expectRevert("not a valid version");
        repo.release(groupId, packageName, version, content);
    }

    function testUpdateRelease() public {
        vm.startPrank(alice);
        repo.register(group);

        string memory packageName = "my-package";
        string memory version = "1.0.0";

        createRelease(packageName, version);

        string[] memory content = new string[](1);
        content[0] = "some other data";

        vm.expectEmit(true, true, true, true);
        emit ReleaseUpdated(groupId, packageName, version, alice);

        repo.release(groupId, packageName, version, content);

        (bool exists, string[] memory content_, bool nuked) = repo.getRelease(
            group,
            packageName,
            version
        );
        assertTrue(exists);
        assertEq(content_.length, 2);
        assertEq(content_[1], content[0]);
        assertFalse(nuked);
    }

    function testGetRelease_empty() public {
        string memory packageName = "my-package";
        string memory version = "1.0.0";

        (bool exists, string[] memory content_, bool nuked) = repo.getRelease(
            group,
            packageName,
            version
        );

        assertFalse(exists);
        assertEq(content_.length, 0);
        assertFalse(nuked);
    }

    function testNukeRelease() public {
        vm.startPrank(alice);
        repo.register(group);

        string memory packageName = "my-package";
        string memory version = "1.0.0";

        createRelease(packageName, version);
        (, string[] memory oldContent, ) = repo.getRelease(
            group,
            packageName,
            version
        );

        vm.expectEmit(true, true, true, true);
        emit ReleaseNuked(groupId, packageName, version, alice);

        repo.nuke(groupId, packageName, version, new string[](0));

        (bool exists, string[] memory content, bool nuked) = repo.getRelease(
            group,
            packageName,
            version
        );
        assertTrue(exists, "release exists");
        assertTrue(nuked, "release nuked");
        assertEq(content.length, 1, "has same content length");
        assertEq(content[0], oldContent[0], "has same content");

        vm.expectEmit(true, true, true, true);
        emit ReleaseUpdated(groupId, packageName, version, alice);

        repo.nuke(groupId, packageName, version, new string[](0));
    }

    /// TODO check requirements on release
    /// TODO access versions tests
    /// TODO access latest version of package tests
}
