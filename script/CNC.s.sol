// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {OfferItem, ConsiderationItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {CampaignParams, CampaignRequirements} from "../src/lib/RedeemablesStructs.sol";
import {ERC721RedemptionMintable} from "../src/extensions/ERC721RedemptionMintable.sol";
import {ERC721OwnerMintable} from "../src/test/ERC721OwnerMintable.sol";
// import {ERC1155ShipyardRedeemableMintable} from "../src/extensions/ERC1155ShipyardRedeemableMintable.sol";
import {Certificate} from "../src/extensions/Certificate.sol";

contract DeployAndConfigure1155Receive is Script, Test {
    address constant _BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    function run() external {
        vm.startBroadcast();

        // arb goerli burn contract
        address redeemToken = 0xE0c4032C59F1DF070DEE602B8ec9136ebE4F2D22;

        Certificate receiveToken = new Certificate("TestCertificate", "TEST-C");

        // Configure the campaign.
        OfferItem[] memory offer = new OfferItem[](3);
        offer[0] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(receiveToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });
        offer[1] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA, // if just ItemType.ERC1155, then could pass merkle root with token ids, etc.
            token: address(receiveToken),
            identifierOrCriteria: 0, // 0=wildcard when with criteria. means any token.
            startAmount: 1,
            endAmount: 1
        });
        offer[2] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(receiveToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(redeemToken),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(_BURN_ADDRESS)
        });

        // example with burning wood
        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[1] = ConsiderationItem({
            itemType: ItemType.ERC155,
            token: address(redeemToken),
            identifierOrCriteria: 1, // wood has token id 1
            startAmount: 100,
            endAmount: 100,
            recipient: payable(_BURN_ADDRESS)
        });

        // specify the campaign at redeem time so the requirements are looked up then
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
        uint256 campaignId = receiveToken.createCampaign(
            params,
            "ipfs://QmQjubc6guHReNW5Es5ZrgDtJRwXk2Aia7BkVoLJGaCRqP"
        );

        // To test updateCampaign, update to proper start/end times.
        params.startTime = uint32(block.timestamp);
        params.endTime = uint32(block.timestamp + 1_000_000);
        receiveToken.updateCampaign(1, params, "");
    }
}
