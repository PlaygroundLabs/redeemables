// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC165} from "openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import {ERC721ConduitPreapproved_Solady} from "shipyard-core/src/tokens/erc721/ERC721ConduitPreapproved_Solady.sol";
import {ConsiderationItem, OfferItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {ERC7498NFTRedeemables} from "../lib/ERC7498NFTRedeemables.sol";
import {CampaignParams} from "../lib/RedeemablesStructs.sol";
import {IRedemptionMintable} from "../interfaces/IRedemptionMintable.sol";
import {ERC721ShipyardRedeemable} from "../ERC721ShipyardRedeemable.sol";
import {IRedemptionMintable} from "../interfaces/IRedemptionMintable.sol";
import {TraitRedemption} from "../lib/RedeemablesStructs.sol";

contract ERC721ShipyardRedeemableMintable is
    ERC721ShipyardRedeemable,
    IRedemptionMintable
{
    /// @dev The ERC-7498 redeemables contracts.
    address[] internal _erc7498RedeemablesContracts;

    /// @dev The preapproved address.
    address internal _preapprovedAddress;

    /// @dev The preapproved OpenSea conduit address.
    address internal immutable _CONDUIT =
        0x1E0049783F008A0085193E00003D00cd54003c71;

    /// @dev The next token id to mint.
    uint256 _nextTokenId = 1;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721ShipyardRedeemable(name_, symbol_) {}

    function mintRedemption(
        uint256 /* campaignId */,
        address recipient,
        OfferItem calldata, /* offer */
        ConsiderationItem[] calldata, /* consideration */
        TraitRedemption[] calldata /* traitRedemptions */
    ) external {
        // Require that msg.sender is valid.
        _requireValidRedeemablesCaller();

        // Increment nextTokenId first so more of the same token id cannot be minted through reentrancy.
        ++_nextTokenId;

        _mint(recipient, _nextTokenId - 1);
    }

    function getRedeemablesContracts()
        external
        view
        returns (address[] memory)
    {
        return _erc7498RedeemablesContracts;
    }

    function setRedeemablesContracts(
        address[] calldata redeemablesContracts
    ) external onlyOwner {
        _erc7498RedeemablesContracts = redeemablesContracts;
    }

    function _requireValidRedeemablesCaller() internal view {
        // Allow the contract to call itself.
        if (msg.sender == address(this)) return;

        bool validCaller;
        for (uint256 i; i < _erc7498RedeemablesContracts.length; i++) {
            if (msg.sender == _erc7498RedeemablesContracts[i]) {
                validCaller = true;
            }
        }
        if (!validCaller) revert InvalidCaller(msg.sender);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721ShipyardRedeemable) returns (bool) {
        return
            interfaceId == type(IRedemptionMintable).interfaceId ||
            ERC721ShipyardRedeemable.supportsInterface(interfaceId);
    }

    /**
     * @notice Set the preapproved address. Only callable by the owner.
     *
     * @param newPreapprovedAddress The new preapproved address.
     */
    function setPreapprovedAddress(
        address newPreapprovedAddress
    ) external onlyOwner {
        _preapprovedAddress = newPreapprovedAddress;
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets
     *      of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) public view virtual override returns (bool) {
        if (operator == _CONDUIT || operator == _preapprovedAddress) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }
}
