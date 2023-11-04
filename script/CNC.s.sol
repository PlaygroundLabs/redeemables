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
import {ERC721ShipyardRedeemableMintable} from "../src/extensions/ERC721ShipyardRedeemableMintable.sol";

import {ERC721RedemptionMintable} from "../src/extensions/ERC721RedemptionMintable.sol";
import {ERC721ShipyardRedeemableOwnerMintable} from "../src/test/ERC721ShipyardRedeemableOwnerMintable.sol";
import {ERC1155ShipyardRedeemableOwnerMintable} from "../src/test/ERC1155ShipyardRedeemableOwnerMintable.sol";

contract DeployAndConfigure1155Receive is Script, Test {
    function run() external {
        vm.startBroadcast();

        // address cncTreasury = BURN_ADDRESS; // TODO: update
        address cncTreasury = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
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

        ERC721ShipyardRedeemableMintable ships = new ERC721ShipyardRedeemableMintable(
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
        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(certificates),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(cncTreasury) // TODO: burn address here was failing
        });
        // consideration[1] = ConsiderationItem({
        //     itemType: ItemType.ERC1155,
        //     token: address(resources),
        //     identifierOrCriteria: 1,
        //     startAmount: 100,
        //     endAmount: 100,
        //     recipient: payable(cncTreasury)
        // });
        // consideration[2] = ConsiderationItem({
        //     itemType: ItemType.ERC1155,
        //     token: address(resources),
        //     identifierOrCriteria: 2,
        //     startAmount: 100,
        //     endAmount: 100,
        //     recipient: payable(cncTreasury)
        // });
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

        // Mint some tokens for the redeem ingredients
        certificates.mint(msg.sender, 1, 1); // certificate
        resources.mint(msg.sender, 1, 100); // metal // TODO: shoudl this start at 0 or 1?
        resources.mint(msg.sender, 2, 100); // wood

        certificates.setApprovalForAll(address(ships), true);
        resources.setApprovalForAll(address(ships), true);

        assertEq(certificates.balanceOf(msg.sender, 1), 1);
        assertEq(resources.balanceOf(msg.sender, 1), 100);
        assertEq(resources.balanceOf(msg.sender, 2), 100);

        // Call redeem
        // Let's redeem them!
        uint256 campaignId = 1;
        uint256 requirementsIndex = 0;
        bytes32 redemptionHash;
        uint256 salt;
        bytes memory signature;
        bytes memory data = abi.encode(
            campaignId,
            requirementsIndex,
            redemptionHash,
            salt,
            signature
        );

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;
        // tokenIds[1] = 1;
        // tokenIds[2] = 2;
        ships.redeem(tokenIds, msg.sender, data);
    }
}
