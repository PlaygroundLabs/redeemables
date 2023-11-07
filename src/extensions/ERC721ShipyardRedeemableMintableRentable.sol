// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC4907} from "./IERC4907.sol";
import {ERC721ShipyardRedeemableMintable} from "./ERC721ShipyardRedeemableMintable.sol";

contract ERC721ShipyardRedeemableMintableRentable is ERC721ShipyardRedeemableMintable, IERC4907 {
    // This implements ERC4907.
    // following https://docs.double.one/for-developers/integration-docs-for-erc-721/erc-4907-introduction
    struct UserInfo {
        address user; // address of user role
        uint64 expires; // unix timestamp, user expires
    }
    mapping(uint256 => UserInfo) internal _users;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721ShipyardRedeemableMintable(name_, symbol_) {}

    /// @dev See {IERC4907-setUser}
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC4907: transfer caller is not owner nor approved"
        );
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    /// @dev See {IERC4907-userOf}
    function userOf(uint256 tokenId) public view virtual returns (address) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        } else {
            return address(0);
        }
    }

    /// @dev See {IERC4907-userExpires}
    function userExpires(
        uint256 tokenId
    ) public view virtual returns (uint256) {
        return _users[tokenId].expires;
    }

    /// @dev See {IERC165-supportsInterface}
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev delete UserInfo when burn
    function _burn(uint256 tokenId) internal virtual override {
        delete _users[tokenId];
        emit UpdateUser(tokenId, address(0), 0);
        super._burn(tokenId);
    }
}
