// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Donate
 * @dev Basic smart contract for a Web3 donation dApp
 */
contract Donate is ReentrancyGuard {
    address public platformFeeAddress;
    uint256 public platformFeePercentage = 10; // 10%

    struct Item {
        uint256 id;
        string metadataHash;
        address artist;
        uint256 totalDonated;
    }

    mapping(uint256 => Item) public items;
    uint256 public itemCount;

    event ItemCreated(uint256 indexed id, string metadataHash, address indexed artist);
    event DonationReceived(
        uint256 indexed itemId,
        address indexed donor,
        uint256 amount,
        uint256 artistAmount,
        uint256 platformAmount
    );

    constructor(address _platformFeeAddress) {
        require(_platformFeeAddress != address(0), "Invalid platform fee address");
        platformFeeAddress = _platformFeeAddress;
    }

    /**
     * @dev Store an item with a metadata hash
     * @param _metadataHash The hash of the item's metadata (IPFS CID, etc.)
     */
    function createItem(string memory _metadataHash) external {
        itemCount++;
        items[itemCount] = Item({
            id: itemCount,
            metadataHash: _metadataHash,
            artist: msg.sender,
            totalDonated: 0
        });

        emit ItemCreated(itemCount, _metadataHash, msg.sender);
    }

    /**
     * @dev Allow users to donate ETH/MATIC to an item
     * @param _itemId The ID of the item to donate to
     */
    function donate(uint256 _itemId) external payable nonReentrant {
        require(_itemId > 0 && _itemId <= itemCount, "Item does not exist");
        require(msg.value > 0, "Donation amount must be greater than 0");

        Item storage item = items[_itemId];

        uint256 platformAmount = (msg.value * platformFeePercentage) / 100;
        uint256 artistAmount = msg.value - platformAmount;

        item.totalDonated += msg.value;

        // Split donation
        (bool successPlatform, ) = payable(platformFeeAddress).call{ value: platformAmount }("");
        require(successPlatform, "Platform fee transfer failed");

        (bool successArtist, ) = payable(item.artist).call{ value: artistAmount }("");
        require(successArtist, "Artist transfer failed");

        emit DonationReceived(_itemId, msg.sender, msg.value, artistAmount, platformAmount);
    }

    /**
     * @dev Update platform fee percentage
     * @param _newPercentage New platform fee percentage (0-100)
     */
    function updatePlatformFee(uint256 _newPercentage) external {
        // Restricted to the owner in a real dApp.
        // Simplified for scaffolding.
        require(_newPercentage <= 100, "Percentage must be between 0 and 100");
        platformFeePercentage = _newPercentage;
    }
}
