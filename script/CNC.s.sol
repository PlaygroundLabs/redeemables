// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Resources} from "../src/extensions/Resources.sol";
import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {OfferItem, ConsiderationItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {Campaign, CampaignParams, CampaignRequirements, TraitRedemption} from "../src/lib/RedeemablesStructs.sol";
import {BURN_ADDRESS} from "../src/lib/RedeemablesConstants.sol";

import {TestERC20} from "../test/utils/mocks/TestERC20.sol";
import {ERC721ShipyardRedeemableMintable} from "../src/extensions/ERC721ShipyardRedeemableMintable.sol";
import {ERC1155ShipyardRedeemableMintable} from "../src/extensions/ERC1155ShipyardRedeemableMintable.sol";
import {ERC721ShipyardRedeemableMintableRentable} from "../src/extensions/ERC721ShipyardRedeemableMintableRentable.sol";

contract CNCContractScript is Script, Test {
    address CNC_TREASURY = 0x2DC39C543028933ea5e45851Fa84ad8F95C4c1DE; // TODO: update me later

    // 0x6365727454797065000000000000000000000000000000000000000000000000
    bytes32 traitKey = bytes32("certType");

    bytes32 traitValueWraithBlueprint = bytes32(uint256(1));
    bytes32 traitValueWraithGoldprint = bytes32(uint256(2));
    bytes32 traitValueClockworkBlueprint = bytes32(uint256(3));
    bytes32 traitValueClockworkGoldprint = bytes32(uint256(4));
    bytes32 traitValueT1Lumber = bytes32(uint256(5));
    bytes32 traitValueT2Lumber = bytes32(uint256(6));
    bytes32 traitValueT3Lumber = bytes32(uint256(7));
    bytes32 traitValueT1Ore = bytes32(uint256(8));
    bytes32 traitValueT2Ore = bytes32(uint256(9));
    bytes32 traitValueT3Ore = bytes32(uint256(10));
    bytes32 traitValueHat1 = bytes32(uint256(11)); // straw hat
    bytes32 traitValueHat2 = bytes32(uint256(12)); // horned helm
    bytes32 traitValueHat3 = bytes32(uint256(13)); // tinkerer's goggles
    bytes32 traitValueEyepiece1 = bytes32(uint256(14)); // eyepatch
    bytes32 traitValueEyepiece2 = bytes32(uint256(15)); // carnival mask
    bytes32 traitValueEyepiece3 = bytes32(uint256(16)); // rose tinted moncole
    bytes32 traitValueCannon1 = bytes32(uint256(17)); // star cannon
    bytes32 traitValueCannon2 = bytes32(uint256(18)); // pink party cannon
    bytes32 traitValueCannon3 = bytes32(uint256(19)); // skeletal cannon

    uint32 t1LumberTokenId = 1;
    uint32 t2LumberTokenId = 2;
    uint32 t3LumberTokenId = 3;
    uint32 t1OreTokenId = 4;
    uint32 t2OreTokenId = 5;
    uint32 t3OreTokenId = 6;
    uint32 shipLumberConsidered = 30_000;
    uint32 shipOreConsidered = 15_000;
    uint256 wraithEthConsidered = 0.050 ether;
    uint256 clockworkEthConsidered = 0.015 ether;
    uint32 resourcesOffered = 10_000;

    // uint32 campaignStartTime = 1698796800; //  seconds since epoch - nov 1 2023
    uint32 campaignStartTime = 1700586000; //  nov 21, 12pm ET
    uint32 campaignEndTime = 2016037538; // seconds since epoch  - nov 19 2033
    uint32 maxCertificateCampaignRedemptions = 6_500; // for the lootbox/certs campaign
    uint32 maxCampaignRedemptions = 100_000; // for all other campaigns

    string certCampainURI =
        "ipfs://Qmd1svWLxdjRUCxDCv6i6MFZtcU6SY56mD6JM8Ds1ZrXPB";

    function testLootboxRedeem(
        address lootboxesAdddr,
        address certificatesAddr
    ) public {
        uint campaignId = 1;
        uint tokenId = 1;
        ERC721ShipyardRedeemableMintable lootboxes = ERC721ShipyardRedeemableMintable(
                lootboxesAdddr
            );

        ERC1155ShipyardRedeemableMintable certificates = ERC1155ShipyardRedeemableMintable(
                certificatesAddr
            );

        lootboxes.mint(msg.sender, tokenId);

        assertEq(lootboxes.balanceOf(msg.sender), 1); // confirm they have the lootbox
        assertEq(certificates.balanceOf(msg.sender, 1), 0);
        assertEq(certificates.balanceOf(msg.sender, 2), 0);
        assertEq(certificates.balanceOf(msg.sender, 3), 0);
        assertEq(certificates.balanceOf(msg.sender, 4), 0);
        assertEq(certificates.balanceOf(msg.sender, 5), 0);
        assertEq(certificates.balanceOf(msg.sender, 6), 0);

        uint256[] memory traitRedemptionTokenIds = new uint256[](0);
        bytes memory data = abi.encode(
            campaignId,
            0,
            bytes32(0),
            traitRedemptionTokenIds,
            uint256(0),
            bytes("")
        );

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;

        certificates.redeem(tokenIds, msg.sender, data);

        // confirm msg.sender got the right number of certs
        assertEq(certificates.balanceOf(msg.sender, 1), 1);
        assertEq(certificates.balanceOf(msg.sender, 2), 1);
        assertEq(certificates.balanceOf(msg.sender, 3), 1);
        assertEq(certificates.balanceOf(msg.sender, 4), 1);
        assertEq(certificates.balanceOf(msg.sender, 5), 1);
        assertEq(certificates.balanceOf(msg.sender, 6), 0);

        // confirm they no longer have the lootbox
        assertEq(lootboxes.balanceOf(msg.sender), 0);
    }

    function setUpCertificatesCampaign(
        address lootboxesAddr,
        address certificatesAddr
    ) public returns (uint256) {
        // Setups the certificates campaign.
        // A single lootbox should yield a certificate.

        ERC1155ShipyardRedeemableMintable certificates = ERC1155ShipyardRedeemableMintable(
                certificatesAddr
            );

        OfferItem[] memory offer = new OfferItem[](5);
        offer[0] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: certificatesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });
        offer[1] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: certificatesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });
        offer[2] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: certificatesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });
        offer[3] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: certificatesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });
        offer[4] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: certificatesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: lootboxesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });

        // Create the second campaign for goldprint
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;

        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCertificateCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint campaignId = certificates.createCampaign(
            campaign,
            "ipfs://Qmd1svWLxdjRUCxDCv6i6MFZtcU6SY56mD6JM8Ds1ZrXPB" // TODO:
        );
        // uint campaignId = 1;
        // certificates.updateCampaign(
        //     campaignId,
        //     params,
        //     "ipfs://Qmd1svWLxdjRUCxDCv6i6MFZtcU6SY56mD6JM8Ds1ZrXPB"
        // );
        return campaignId;
    }

    function setUpWraithBlueprintCampaign(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr
    ) public returns (uint256) {
        ERC721ShipyardRedeemableMintable ships = ERC721ShipyardRedeemableMintable(
                shipsAddr
            );

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(ships),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](4);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(certificatesAddr),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });

        consideration[1] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resourcesAddr),
            identifierOrCriteria: t3LumberTokenId,
            startAmount: shipLumberConsidered,
            endAmount: shipLumberConsidered,
            recipient: payable(BURN_ADDRESS)
        });

        consideration[2] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resourcesAddr),
            identifierOrCriteria: t3OreTokenId,
            startAmount: shipOreConsidered,
            endAmount: shipOreConsidered,
            recipient: payable(BURN_ADDRESS)
        });

        consideration[3] = ConsiderationItem({
            itemType: ItemType.NATIVE,
            token: address(0),
            identifierOrCriteria: 0,
            startAmount: wraithEthConsidered,
            endAmount: wraithEthConsidered,
            recipient: payable(CNC_TREASURY)
        });

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: address(certificatesAddr),
            traitKey: traitKey,
            traitValue: traitValueWraithBlueprint, // new trait value
            substandardValue: traitValueWraithBlueprint // required previous value
        });

        // Create the first campaign for blueprints
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;

        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint campaignId = ships.createCampaign(campaign, certCampainURI);

        return campaignId;
    }

    function setUpWraithGoldprintCampaign(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr
    ) public returns (uint256) {
        // Setups the goldprint campaign for the wraith ship
        // Considerations:
        // - certificate with the goldprint dynamic trait
        // - offer: a ship
        ERC721ShipyardRedeemableMintable ships = ERC721ShipyardRedeemableMintable(
                shipsAddr
            );

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(ships),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(certificatesAddr),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: address(certificatesAddr),
            traitKey: traitKey,
            traitValue: traitValueWraithGoldprint, // new trait value
            substandardValue: traitValueWraithGoldprint // required previous value
        });

        // Create the second campaign for goldprint
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;

        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint campaignId = ships.createCampaign(
            campaign,
            "ipfs://QmQjubc6guHReNW5Es5ZrgDtJRwXk2Aia7BkVoLJGaCRqP"
        );

        return campaignId;
    }

    function setUpClockworkBlueprintCampaign(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr
    ) public returns (uint256) {
        // Creates a campaigns for clockwork ship from a blueprint.

        ERC721ShipyardRedeemableMintable ships = ERC721ShipyardRedeemableMintable(
                shipsAddr
            );

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(ships),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](4);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(certificatesAddr),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });

        consideration[1] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resourcesAddr),
            identifierOrCriteria: t2LumberTokenId,
            startAmount: shipLumberConsidered,
            endAmount: shipLumberConsidered,
            recipient: payable(BURN_ADDRESS)
        });

        consideration[2] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resourcesAddr),
            identifierOrCriteria: t2OreTokenId,
            startAmount: shipOreConsidered,
            endAmount: shipOreConsidered,
            recipient: payable(BURN_ADDRESS)
        });

        consideration[3] = ConsiderationItem({
            itemType: ItemType.NATIVE,
            token: address(0),
            identifierOrCriteria: 0,
            startAmount: clockworkEthConsidered,
            endAmount: clockworkEthConsidered,
            recipient: payable(CNC_TREASURY)
        });

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: address(certificatesAddr),
            traitKey: traitKey,
            traitValue: traitValueClockworkBlueprint, // new trait value
            substandardValue: traitValueClockworkBlueprint // required previous value
        });

        // Create the first campaign for blueprints
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;

        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint campaignId = ships.createCampaign(
            campaign,
            "ipfs://QmQjubc6guHReNW5Es5ZrgDtJRwXk2Aia7BkVoLJGaCRqP"
        );
        return campaignId;
    }

    function setUpClockworkGoldprintCampaign(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr
    ) public returns (uint256) {
        // Setups the goldprint campaign
        // Considerations:
        // - certificate with the goldprint dynamic trait
        // - offer: a ship
        ERC721ShipyardRedeemableMintable ships = ERC721ShipyardRedeemableMintable(
                shipsAddr
            );

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: address(ships),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(certificatesAddr),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: address(certificatesAddr),
            traitKey: traitKey,
            traitValue: traitValueClockworkGoldprint, // new trait value
            substandardValue: traitValueClockworkGoldprint // required previous value
        });

        // Create the second campaign for goldprint
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;
        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint campaignId = ships.createCampaign(
            campaign,
            "ipfs://QmQjubc6guHReNW5Es5ZrgDtJRwXk2Aia7BkVoLJGaCRqP"
        );

        return campaignId;
    }

    function setUpShipCampaigns(
        address shipsAddr,
        address certificatesAddr,
        address resourcesAddr
    ) public {
        // Sets up all four ship campaigns
        setUpWraithBlueprintCampaign(
            shipsAddr,
            certificatesAddr,
            resourcesAddr
        );

        setUpWraithGoldprintCampaign(
            shipsAddr,
            certificatesAddr,
            resourcesAddr
        );

        setUpClockworkBlueprintCampaign(
            shipsAddr,
            certificatesAddr,
            resourcesAddr
        );

        setUpClockworkGoldprintCampaign(
            shipsAddr,
            certificatesAddr,
            resourcesAddr
        );
    }

    function setUpResourcesCampaign(
        address certificatesAddr,
        address resourcesAddr,
        bytes32 traitValue,
        uint32 resourcesTokenId
    ) public returns (uint256) {
        // Sets up a single campaign for resources given the parameters
        ERC1155ShipyardRedeemableMintable resources = ERC1155ShipyardRedeemableMintable(
                resourcesAddr
            );

        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: resourcesAddr,
            identifierOrCriteria: resourcesTokenId,
            startAmount: resourcesOffered,
            endAmount: resourcesOffered
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: address(certificatesAddr),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: address(certificatesAddr),
            traitKey: traitKey,
            traitValue: traitValue, // new trait value
            substandardValue: traitValue // required previous value
        });

        // Create the second campaign for goldprint
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;
        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint256 campaignId = ERC1155ShipyardRedeemableMintable(resourcesAddr)
            .createCampaign(campaign, "uri://");
        return campaignId;
    }

    function setUpResourcesCampaigns(
        address resourcesAddr,
        address certificatesAddr
    ) public {
        // Sets up all the resources campaigns
        setUpResourcesCampaign( // t1 lumber
            certificatesAddr,
            resourcesAddr,
            traitValueT1Lumber,
            t1LumberTokenId
        );
        setUpResourcesCampaign( // t2 lumber
            certificatesAddr,
            resourcesAddr,
            traitValueT2Lumber,
            t2LumberTokenId
        );
        setUpResourcesCampaign( // t3 lumber
            certificatesAddr,
            resourcesAddr,
            traitValueT3Lumber,
            t3LumberTokenId
        );
        setUpResourcesCampaign( // t1 ore
            certificatesAddr,
            resourcesAddr,
            traitValueT1Ore,
            t1OreTokenId
        );
        setUpResourcesCampaign( // t2 ore
            certificatesAddr,
            resourcesAddr,
            traitValueT2Ore,
            t2OreTokenId
        );
        setUpResourcesCampaign( // t3 ore
            certificatesAddr,
            resourcesAddr,
            traitValueT3Ore,
            t3OreTokenId
        );
    }

    function setUpCosmeticsCampaign(
        address certificatesAddr,
        address cosmeticsAddr,
        bytes32 traitValue
    ) public returns (uint256) {
        OfferItem[] memory offer = new OfferItem[](1);
        offer[0] = OfferItem({
            itemType: ItemType.ERC721_WITH_CRITERIA,
            token: cosmeticsAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1
        });

        ConsiderationItem[] memory consideration = new ConsiderationItem[](1);
        consideration[0] = ConsiderationItem({
            itemType: ItemType.ERC1155_WITH_CRITERIA,
            token: certificatesAddr,
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: certificatesAddr,
            traitKey: traitKey,
            traitValue: traitValue, // new trait value
            substandardValue: traitValue // required previous value
        });

        // Create the second campaign for goldprint
        CampaignRequirements[] memory requirements = new CampaignRequirements[](
            1
        );
        requirements[0].offer = offer;
        requirements[0].consideration = consideration;
        requirements[0].traitRedemptions = traitRedemptions;
        CampaignParams memory params = CampaignParams({
            signer: address(0),
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        Campaign memory campaign = Campaign({
            params: params,
            requirements: requirements
        });

        uint256 campaignId = ERC721ShipyardRedeemableMintable(cosmeticsAddr)
            .createCampaign(campaign, "uri://");
        return campaignId;
    }

    function setUpCosmeticsCampaigns(
        address cosmeticsAddr,
        address certificatesAddr
    ) public {
        setUpCosmeticsCampaign(certificatesAddr, cosmeticsAddr, traitValueHat1);
        setUpCosmeticsCampaign(certificatesAddr, cosmeticsAddr, traitValueHat2);
        setUpCosmeticsCampaign(certificatesAddr, cosmeticsAddr, traitValueHat3);
        setUpCosmeticsCampaign(
            certificatesAddr,
            cosmeticsAddr,
            traitValueEyepiece1
        );
        setUpCosmeticsCampaign(
            certificatesAddr,
            cosmeticsAddr,
            traitValueEyepiece2
        );
        setUpCosmeticsCampaign(
            certificatesAddr,
            cosmeticsAddr,
            traitValueEyepiece3
        );
        setUpCosmeticsCampaign(
            certificatesAddr,
            cosmeticsAddr,
            traitValueCannon1
        );
        setUpCosmeticsCampaign(
            certificatesAddr,
            cosmeticsAddr,
            traitValueCannon2
        );
        setUpCosmeticsCampaign(
            certificatesAddr,
            cosmeticsAddr,
            traitValueCannon3
        );
    }

    function mintAndSetTraits(address certificatesAddr) public {
        // Test function for minting and setting traits
        // I used this set up some test certificates for chris
        ERC1155ShipyardRedeemableMintable certificates = ERC1155ShipyardRedeemableMintable(
                certificatesAddr
            );
        // for (uint i = 10; i < 60; i++) {
        //     certificates.mint(msg.sender, i, 1); // certificate
        // }

        // for (uint i = 10; i < 60; i++) {
        //     certificates.setTrait(i, traitKey, traitValueWraithGoldprint);
        // }

        for (uint i = 1; i < 6; i++) {
            uint tokenIdBase = 100000 + (i * 100);
            for (uint j = 1; j <= 19; j++) {
                uint tokenId = tokenIdBase + j;
                bytes32 traitValue = bytes32(j);

                certificates.mint(msg.sender, tokenId, 1); // certificate
                certificates.setTrait(tokenId, traitKey, traitValue);
            }
        }
    }

    function run() external {
        // Instructions for running:
        // Run anvil in another terminal
        // For the PK, I was using the first wallet from Anvil
        // Run export PK=
        // Run: export RPC_URL="http://127.0.0.1:8545"
        // Run: forge script script/CNC.s.sol --rpc-url ${RPC_URL} --private-key ${PK}  -vvvv

        vm.startBroadcast();

        // Deploy the contracts
        // ERC721ShipyardRedeemableMintableRentable lootboxes = new ERC721ShipyardRedeemableMintableRentable(
        //         "Captain & Company - Clockwork Lootbox",
        //         "CNC-CLBX"
        //     );

        ERC1155ShipyardRedeemableMintable certificates = new ERC1155ShipyardRedeemableMintable(
                "Captain & Company - Certificates",
                "CNC-CERTS"
            );

        // Resources resources = new Resources(
        //     "Captain & Company - Resources",
        //     "CNC-RSRCS"
        // );

        // ERC721ShipyardRedeemableMintableRentable ships = new ERC721ShipyardRedeemableMintableRentable(
        //         "Captain & Company - Ships",
        //         "CNC-SHIPS"
        //     );

        // ERC721ShipyardRedeemableMintable cosmetics = new ERC721ShipyardRedeemableMintable(
        //         "Cosmetics",
        //         "CNS-COSM"
        // );

        // address lootboxesAddr = address(lootboxes);
        // address shipsAddr = address(ships);
        address certificatesAddr = address(certificates);
        // address resourcesAddr = address(resources);
        // address cosmeticsAddr = address(cosmetics);

        // Arbitrum Goerli addresses (v2 deployment)
        // address lootboxesAddr = 0x95A863f964534527f733e2fA1f4B09D7076A80ef;
        // address shipsAddr = 0xa38D0828B6a9432C6adfdA0557cD6378AfCeaE1B;
        // address certificatesAddr = 0x5e1a8F974642dE67a43587A469b143f39444223d;
        // address resourcesAddr = 0x6fdb1978218A3f31dAF107875Ae25a930A1A1EF1;
        // address cosmeticsAddr = 0x479750c63C3243375A52115C0987c4f78B48c398;

        // Sepolia v2 addresses
        // address certificatesAddr = 0xDa2eBf447B5a3d7d3C1201BF185e9c031765425e;

        // Sepolia v5 addresses
        // address certificatesAddr = 0xCce4a77f18e20C2526088631FA849CD20F629f0A;
        // address shipsAddr = 0x830AcC5cfE34A5A2f988AF783611a7166f88C0d1;
        // address resourcesAddr = 0xaDCA84042C628A04009E2375E8879F874f2E971D;

        // Arbitrum Mainnet
        address lootboxesAddr = 0xDEEBFE062Ea7F30b2B13e3B075FA0Bb1F7cEbB85;

        // Used for on-chain, not locally
        // mintAndSetTraits(certificatesAddr);

        setUpCertificatesCampaign(lootboxesAddr, certificatesAddr);

        // setUpWraithBlueprintCampaign(
        //     shipsAddr,
        //     certificatesAddr,
        //     resourcesAddr
        // );

        // setUpClockworkBlueprintCampaign(
        //     shipsAddr,
        //     certificatesAddr,
        //     resourcesAddr
        // );

        // setUpShipCampaigns(shipsAddr, certificatesAddr, resourcesAddr);
        // setUpResourcesCampaigns(resourcesAddr, certificatesAddr);
        // setUpCosmeticsCampaigns(cosmeticsAddr, certificatesAddr);

        // testLootboxRedeem(lootboxesAddr, certificatesAddr);

        // testRentals(shipsAddr);
    }
}
