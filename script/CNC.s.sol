// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {OfferItem, ConsiderationItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {CampaignParams, CampaignRequirements} from "../src/lib/RedeemablesStructs.sol";
import {BURN_ADDRESS} from "../src/lib/RedeemablesConstants.sol";
import {ERC721RedemptionMintable} from "../src/extensions/ERC721RedemptionMintable.sol";
import {ERC721OwnerMintable} from "../src/test/ERC721OwnerMintable.sol";

// TODO: switched to owner mintable

// import {ERC1155ShipyardRedeemableMintable} from "../src/extensions/ERC1155ShipyardRedeemableMintable.sol";
// import {ERC721ShipyardRedeemableMintable} from "../src/extensions/ERC721ShipyardRedeemableMintable.sol";

import {ERC721ShipyardRedeemableOwnerMintable} from "../src/test/ERC721ShipyardRedeemableOwnerMintable.sol";
import {ERC1155ShipyardRedeemableOwnerMintable} from "../src/test/ERC1155ShipyardRedeemableOwnerMintable.sol";

contract DeployAndConfigure1155Receive is Script, Test {
    function run() external {
        vm.startBroadcast();

        address cncTreasury = BURN_ADDRESS; // TODO: update
        address weth = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;

        // make the tokens
        ERC1155ShipyardRedeemableOwnerMintable certificates = new ERC1155ShipyardRedeemableOwnerMintable(
                "Certificates",
                "CERTS"
            );

        ERC1155ShipyardRedeemableOwnerMintable resources = new ERC1155ShipyardRedeemableOwnerMintable(
                "Resources",
                "RSRCS"
            );

        ERC721ShipyardRedeemableOwnerMintable ships = new ERC721ShipyardRedeemableOwnerMintable(
                "Ships",
                "SHIPS"
            );

        // Configure the campaign for ships

        // Configure the offers. These are the what the user receives from the redemption
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(ships),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        // Configure the considerations. These are the inputs to the redeem,
        // the things the user should must have in order to recieve the offer items
        ConsiderationItem[] memory consideration = new ConsiderationItem[](3);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(certificates),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });
        consideration[1] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resources),
            identifierOrCriteria: 1,
            startAmount: 100,
            endAmount: 100,
            recipient: payable(cncTreasury)
        });
        consideration[2] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resources),
            identifierOrCriteria: 2,
            startAmount: 100,
            endAmount: 100,
            recipient: payable(cncTreasury)
        });
        // TODO: ask Ryan about how to do an ERC20 here
        // consideration[3] = ConsiderationItem({
        //     itemType: ItemType.ERC20_WITH_CRITERIA,
        //     token: address(resources),
        //     identifierOrCriteria: 0,
        //     startAmount: 200,
        //     endAmount: 200,
        //     recipient: payable(cncTreasury)
        // });

        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;

        CampaignParams memory params = CampaignParams({
            requirements: requirements,
            signer: address(0),
            startTime: 0,
            endTime: 0,
            maxCampaignRedemptions: 1_000,
            manager: msg.sender
        });
        ships.createCampaign(
            params,
            "ipfs://QmQjubc6guHReNW5Es5ZrgDtJRwXk2Aia7BkVoLJGaCRqP"
        );

        // To test updateCampaign, update to proper start/end times.
        params.startTime = uint32(block.timestamp);
        params.endTime = uint32(block.timestamp + 1_000_000);
        ships.updateCampaign(1, params, "");

        // Mint some tokens

        // function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        // _mint(address(certificates), msg.sender, 1, 100, ""); // metal
        ships.mint(msg.sender, 1); // ship
        // _mint(msg.sender, 2, 100, ""); // wood
    }
}
