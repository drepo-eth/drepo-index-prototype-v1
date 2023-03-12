// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface IRepositoryIndexEvents {
    event GroupCreated(
        address indexed owner,
        uint256 indexed groupId,
        string indexed groupName
    );

    event ReleaseCreated(
        uint256 indexed groupId,
        string indexed packageName,
        string indexed version,
        address creator
    );

    event ReleaseUpdated(
        uint256 indexed groupId,
        string indexed packageName,
        string indexed version,
        address creator
    );

    event ReleaseNuked(
        uint256 indexed groupId,
        string indexed packageName,
        string indexed version,
        address creator
    );
}

interface IRepositoryIndex is IERC721 {
    /// @notice Registers a group with the given name to the message sender
    /// @dev Creates a ERC721 token representing the requests group and sends it to the message sender
    /// @param groupName Name of the group to be created
    /// @return Token id of the new token representing the new group
    function register(string calldata groupName) external returns (uint256);

    /// @notice Creates a new release of a package or appends content to an existing one
    /// @dev Creates or updates a package with the given version and add the given content data
    /// @param tokenId Token id of the group to create the package in
    /// @param package The name of the package
    /// @param version The new version to be created
    /// @param content Content data to be added to the release
    function release(
        uint256 tokenId,
        string calldata package,
        string calldata version,
        string[] calldata content
    ) external;

    /// @notice Loads release data for the given coordinates
    /// @dev Loads release data from string representation of coordinates
    /// @param groupName the group to search in
    /// @param packageName the package to search in
    /// @param version the version to look for
    /// @return returns a flag whether or not a release exists, a versions content and nuke flag, the content array is empty if no release is found
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
        );

    /// @notice Loads released versions of a package in the order they were released
    /// @dev Loads released versions of a package in the order they were released
    /// @param groupName name of the group the package is living in
    /// @param packageName name of the package
    /// @return List of released versions in the order they were released or empty list of there is no package
    function getVersions(string calldata groupName, string calldata packageName)
        external
        view
        returns (string[] memory);

    /// @notice Looks up the latest released version
    /// @dev Looks up the latest released version
    /// @param groupName the group to look for
    /// @param packageName the packageName to look for
    /// @return exits flag and the latest version string
    function getLatestVersion(
        string calldata groupName,
        string calldata packageName
    ) external view returns (bool, string memory);

    /// @notice Nukes an existing release and adds content to it if any is provided
    /// @dev Nukes or updates a nuked package with the given version and adds the given content data
    /// @param tokenId Token id of the group to create the package in
    /// @param package The name of the package
    /// @param version The version to be nuked
    /// @param content Content data to be added to the nuked release
    function nuke(
        uint256 tokenId,
        string calldata package,
        string calldata version,
        string[] calldata content
    ) external;
}
