// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/*

ERC-4907 a new standart witch is a extention for ERC721, this will add two new fetacher:

user ( who use it): whom can have this token for limited time.( rent it )
expires: the time that user can owner it.

 */
interface IERC4907 {
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);
    function setUser(uint256 tokenId, address user, uint64 expires) external;
    function userOf(uint256 tokenId) external view returns (address);
    function userExpires(uint256 tokenId) external view returns (uint256);
}

contract RentableNFT is ERC721URIStorage, IERC4907, Ownable {
    struct UserInfo {
        address user;
        uint64 expires;
    }

    mapping(uint256 => UserInfo) internal _users;
    uint256 public tokenCounter;

    constructor() ERC721("RentableNFT", "RENT") {}

    function mint(string memory uri) external onlyOwner {
        uint256 tokenId = tokenCounter;
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        tokenCounter++;
    }

    function setUser(uint256 tokenId, address user, uint64 expires) external override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");
        _users[tokenId] = UserInfo(user, expires);
        emit UpdateUser(tokenId, user, expires);
    }

    function userOf(uint256 tokenId) public view override returns (address) {
        if (uint64(block.timestamp) <= _users[tokenId].expires) {
            return _users[tokenId].user;
        } else {
            return address(0);
        }
    }

    function userExpires(uint256 tokenId) public view override returns (uint256) {
        return _users[tokenId].expires;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return super.ownerOf(tokenId);
    }

    // Optional: reset user when NFT is transferred
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override {
        if (_users[tokenId].user != address(0)) {
            delete _users[tokenId];
            emit UpdateUser(tokenId, address(0), 0);
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}
