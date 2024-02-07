// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721Enumerable, Ownable {
    // Structure to hold listing information
    struct Listing {
        uint256 tokenId;    // ID of the listed NFT
        address seller;     // Address of the seller
        uint256 price;      // Listing price
        bool active;        // Indicates if the listing is active
    }

    uint256 public feePercentage;               // Fee percentage charged by the marketplace
    mapping(uint256 => Listing) public listings; // Mapping to store listings by token ID

    // Event emitted when a listing is created
    event ListingCreated(uint256 indexed tokenId, address indexed seller, uint256 price);

    // Event emitted when a listing is removed
    event ListingRemoved(uint256 indexed tokenId);

    // Event emitted when an NFT is purchased
    event NFTPurchased(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price);

    constructor() ERC721("NFTMarketplace", "NFTM") {
        feePercentage = 5; // Default fee percentage of 5%
    }

    // Function to list an NFT for sale
    function listNFT(uint256 tokenId, uint256 price) external {
        require(_exists(tokenId), "NFTMarketplace: Token does not exist");
        require(ownerOf(tokenId) == _msgSender(), "NFTMarketplace: Caller is not the owner");

        listings[tokenId] = Listing(tokenId, _msgSender(), price, true);
        emit ListingCreated(tokenId, _msgSender(), price);
    }

    // Function to remove a listing
    function removeListing(uint256 tokenId) external {
        require(listings[tokenId].active, "NFTMarketplace: Listing not found");
        require(listings[tokenId].seller == _msgSender(), "NFTMarketplace: Caller is not the seller");

        delete listings[tokenId];
        emit ListingRemoved(tokenId);
    }

    // Function to purchase an NFT
    function purchaseNFT(uint256 tokenId) external payable {
        require(listings[tokenId].active, "NFTMarketplace: Listing not found");
        uint256 price = listings[tokenId].price;
        address payable seller = payable(listings[tokenId].seller);

        require(msg.value >= price, "NFTMarketplace: Insufficient payment");

        // Calculate fee amount
        uint256 feeAmount = (price * feePercentage) / 100;
        uint256 sellerAmount = price - feeAmount;

        // Send payment to seller
        seller.transfer(sellerAmount);

        // Transfer ownership of NFT to the buyer
        _transfer(seller, _msgSender(), tokenId);

        // Remove the listing
        delete listings[tokenId];

        emit NFTPurchased(tokenId, seller, _msgSender(), price);
    }

    // Function to update the fee percentage
    function updateFeePercentage(uint256 newFeePercentage) external onlyOwner {
        feePercentage = newFeePercentage;
    }

    // Function to get the total number of active listings
    function getTotalListings() external view returns (uint256) {
        uint256 totalListings = 0;
        for (uint256 i = 0; i < totalSupply(); i++) {
            if (listings[i].active) {
                totalListings++;
            }
        }
        return totalListings;
    }
}