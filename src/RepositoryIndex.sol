// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IRepositoryIndex, IRepositoryIndexEvents} from "./IRepositoryIndex.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract RepositoryIndex is IRepositoryIndex, IRepositoryIndexEvents, ERC721 {
    struct Package {
        string[] versions;
        mapping(string => Release) versionMap;
    }

    struct Release {
        string[] content;
        bool nuked;
    }

    mapping(uint256 => string) public groupMap;

    ///     groupName =>       packageName
    mapping(uint256 => mapping(string => Package)) internal packages;

    constructor() ERC721("Decentralized Repository Group", "DREPO_GROUP") {}

    function isValidName(string calldata name) private pure returns (bool) {
        bytes memory b = bytes(name);
        uint256 len = b.length;
        if (len == 0) {
            // must have some chars
            return false;
        }

        for (uint256 i = 0; i < len; i++) {
            bytes1 char = b[i];
            if (
                char != 0x2E && // .
                char != 0x2D && // -
                !(char >= 0x30 && char <= 0x39) && // 0-9
                !(char >= 0x41 && char <= 0x5A) && // A-Z
                !(char >= 0x61 && char <= 0x7A) // 0-9
            ) {
                return false;
            }
        }

        return true;
    }

    function register(string calldata groupName) external returns (uint256) {
        require(isValidName(groupName), "Not a valid name");

        /// TODO make token convert a helper function
        uint256 tokenId = uint256(keccak256(abi.encodePacked(groupName)));

        groupMap[tokenId] = groupName;

        _safeMint(msg.sender, tokenId);

        emit GroupCreated(msg.sender, tokenId, groupName);

        return tokenId;
    }

    function release(
        uint256 tokenId,
        string calldata packageName,
        string calldata version,
        string[] calldata content
    ) external {
        require(ownerOf(tokenId) == msg.sender, "not owner of group");
        require(content.length > 0, "no content provided");
        require(isValidName(packageName), "not a valid name");
        require(isValidName(version), "not a valid version");

        Package storage package = packages[tokenId][packageName];
        Release storage release_ = package.versionMap[version];

        if (release_.content.length > 0) {
            /// update release
            for (uint256 i = 0; i < content.length; i++) {
                release_.content.push(content[i]);
            }

            emit ReleaseUpdated(tokenId, packageName, version, msg.sender);
        } else {
            /// new release
            package.versions.push(version);
            release_.content = content;
            emit ReleaseCreated(tokenId, packageName, version, msg.sender);
        }
    }

    function getRelease(
        string calldata groupName,
        string calldata packageName,
        string calldata version
    )
        external
        view
        returns (
            bool,
            string[] memory,
            bool
        )
    {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(groupName)));

        Release memory release_ = packages[tokenId][packageName].versionMap[
            version
        ];

        /// TODO combine expression? for gas optimization
        if (release_.content.length > 0) {
            return (true, release_.content, release_.nuked);
        }
        return (false, new string[](0), false);
    }

    function getVersions(string calldata groupName, string calldata packageName)
        external
        view
        returns (string[] memory)
    {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(groupName)));

        string[] memory versions = packages[tokenId][packageName].versions;

        return versions;
    }

    function getLatestVersion(
        string calldata groupName,
        string calldata packageName
    ) external view returns (bool, string memory) {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(groupName)));

        string[] memory versions = packages[tokenId][packageName].versions;

        uint256 len = versions.length;

        if (len > 0) {
            return (true, versions[len - 1]);
        }
        return (false, "");
    }

    function nuke(
        uint256 tokenId,
        string calldata packageName,
        string calldata version,
        string[] calldata content
    ) external {
        require(ownerOf(tokenId) == msg.sender, "not owner of group");

        Package storage package = packages[tokenId][packageName];
        Release storage release_ = package.versionMap[version];
        string[] storage releaseContent = release_.content;

        require(releaseContent.length > 0, "release does not exist");

        if (release_.nuked) {
            /// release already nuked
            emit ReleaseUpdated(tokenId, packageName, version, msg.sender);
        } else {
            /// nuking release
            release_.nuked = true;
            emit ReleaseNuked(tokenId, packageName, version, msg.sender);
        }
        for (uint256 i = 0; i < content.length; i++) {
            releaseContent.push(content[i]);
        }
    }
}
