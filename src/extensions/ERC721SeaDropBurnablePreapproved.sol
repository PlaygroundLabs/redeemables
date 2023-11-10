// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC165} from "openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import {ERC721ConduitPreapproved_Solady} from "shipyard-core/src/tokens/erc721/ERC721ConduitPreapproved_Solady.sol";
import {ConsiderationItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {ERC7498NFTRedeemables} from "../lib/ERC7498NFTRedeemables.sol";
import {CampaignParams} from "../lib/RedeemablesStructs.sol";
import {IRedemptionMintable} from "../interfaces/IRedemptionMintable.sol";
import {ERC721ShipyardRedeemable} from "../ERC721ShipyardRedeemable.sol";
import {IRedemptionMintable} from "../interfaces/IRedemptionMintable.sol";
import {TraitRedemption} from "../lib/RedeemablesStructs.sol";
import {ERC721SeaDrop} from "seadrop/src/ERC721SeaDrop.sol";

contract ERC721SeaDropBurnablePreapproved is ERC721SeaDrop {
    /// @dev The preapproved address.
    address internal _preapprovedAddress;

    /// @dev The preapproved OpenSea conduit address.
    // address internal immutable _CONDUIT =
    // 0x1E0049783F008A0085193E00003D00cd54003c71;

    /**
     * @notice Deploy the token contract with its name, symbol,
     *         and allowed SeaDrop addresses.
     */
    // address[] memory allowedSeaDrop
    constructor(
        string memory name,
        string memory symbol
    ) ERC721SeaDrop(_CONDUIT, _CONDUIT, name, symbol) {}

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

    /**
     * @notice Burns `tokenId`. The caller must own `tokenId` or be an
     *         approved operator.
     *
     * @param tokenId The token id to burn.
     */
    // solhint-disable-next-line comprehensive-interface
    // function burn(uint256 tokenId) external {
    //     _burn(
    //         msg.sender == _preapprovedAddress ? address(0) : msg.sender,
    //         tokenId
    //     );
    // }

    // TODO: For testing
    function mint(address to, uint256 tokenId) public onlyOwner {
        _mint(to, tokenId);
    }
}
