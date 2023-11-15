// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {ERC721ShipyardRedeemableMintable} from "../src/extensions/ERC721ShipyardRedeemableMintable.sol";
import {ItemType} from "seaport-types/src/lib/ConsiderationEnums.sol";
import {ERC721ShipyardRedeemableMintableRentable} from "../src/extensions/ERC721ShipyardRedeemableMintableRentable.sol";
import {CampaignParams, CampaignRequirements, TraitRedemption} from "../src/lib/RedeemablesStructs.sol";
import {OfferItem, ConsiderationItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ERC1155ShipyardRedeemableMintable} from "../src/extensions/ERC1155ShipyardRedeemableMintable.sol";
import {BaseRedeemablesTest} from "./utils/BaseRedeemablesTest.sol";
import {BURN_ADDRESS} from "../src/lib/RedeemablesConstants.sol";
import {CNCContractScript} from "../script/CNC.s.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC721SeaDropBurnablePreapproved} from "../src/extensions/ERC721SeaDropBurnablePreapproved.sol";
import {TestERC20} from "../test/utils/mocks/TestERC20.sol";

contract LootboxTests is Test {
    ERC721SeaDropBurnablePreapproved lootboxes;
    ERC1155ShipyardRedeemableMintable certificates;
    ERC1155ShipyardRedeemableMintable resources;
    ERC721ShipyardRedeemableMintableRentable ships;
    ERC721ShipyardRedeemableMintable cosmetics;
    TestERC20 weth;
    bytes32 traitKey = bytes32("certType");
    bytes32 traitValueClockworkBlueprint = bytes32(uint256(3));
    address CNC_TREASURY = address(0x4444);

    uint32 t1LumberTokenId = 1;
    uint32 t2LumberTokenId = 2;
    uint32 t3LumberTokenId = 3;
    uint32 t1OreTokenId = 4;
    uint32 t2OreTokenId = 5;
    uint32 t3OreTokenId = 6;

    function setUp() public virtual {
        // super.setUp();  // if inheriting

        lootboxes = new ERC721SeaDropBurnablePreapproved(
            "Captain & Company - Clockwork Lootbox",
            "CNC-CLBX"
        );

        certificates = new ERC1155ShipyardRedeemableMintable(
            "Captain & Company - Certificates",
            "CNC-CERTS"
        );

        resources = new ERC1155ShipyardRedeemableMintable(
            "Captain & Company - Resources",
            "CNC-RSRCS"
        );

        ships = new ERC721ShipyardRedeemableMintableRentable(
            "Captain & Company - Ships",
            "CNC-SHIPS"
        );

        cosmetics = new ERC721ShipyardRedeemableMintable(
            "Cosmetics",
            "CNS-COSM"
        );

        weth = new TestERC20();

        lootboxes.setPreapprovedAddress(address(certificates));
    }

    function setUpCertificatesCampaign() private returns (uint256) {
        address certificatesAddr = address(certificates);

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
            token: address(lootboxes),
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
            requirements: requirements,
            signer: address(0),
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + uint32(1_000_000),
            maxCampaignRedemptions: 6500,
            manager: msg.sender
        });

        uint campaignId = certificates.createCampaign(params, "uri://");
        return campaignId;
    }

    function setUpClockworkBlueprintCampaign() private returns (uint256) {
        // Sets up the clockwork blueprint campaign for testing. This is a utility
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
            token: address(certificates),
            identifierOrCriteria: 0,
            startAmount: 1,
            endAmount: 1,
            recipient: payable(BURN_ADDRESS)
        });

        consideration[1] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resources),
            identifierOrCriteria: t2LumberTokenId,
            startAmount: 10,
            endAmount: 10,
            recipient: payable(CNC_TREASURY)
        });

        consideration[2] = ConsiderationItem({
            itemType: ItemType.ERC1155,
            token: address(resources),
            identifierOrCriteria: t2OreTokenId,
            startAmount: 10,
            endAmount: 10,
            recipient: payable(CNC_TREASURY)
        });

        consideration[3] = ConsiderationItem({
            itemType: ItemType.ERC20,
            token: address(weth),
            identifierOrCriteria: 0,
            startAmount: 5,
            endAmount: 5,
            recipient: payable(CNC_TREASURY)
        });

        TraitRedemption[] memory traitRedemptions = new TraitRedemption[](1);
        traitRedemptions[0] = TraitRedemption({
            substandard: 4, // an indicator integer
            token: address(certificates),
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
            requirements: requirements,
            signer: address(0),
            startTime: uint32(block.timestamp),
            endTime: uint32(block.timestamp) + uint32(1_000_000),
            maxCampaignRedemptions: 10_000,
            manager: msg.sender
        });

        uint campaignId = ships.createCampaign(params, "ipfs://!");
        return campaignId;
    }

    function testLootboxCertificatesRedeem() public {
        address addr1 = address(0xDCBA);
        address addr2 = address(0xABCD);
        address addr3 = address(0xCCCC);

        uint certsInTreasuryMint = 1000;
        uint redeemCertTokenId = certsInTreasuryMint + 1;
        uint campaignId = 1;
        uint lootboxTokenId = 1;

        // Mint certificates for the treasury mint
        certificates.adminMint(addr3, certsInTreasuryMint, 1);

        setUpCertificatesCampaign();

        // mint the user a lootbox
        lootboxes.mint(msg.sender, lootboxTokenId);

        assertEq(lootboxes.ownerOf(lootboxTokenId), msg.sender); // confirm they have the lootbox
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
        tokenIds[0] = lootboxTokenId;

        // Verify that redeeming as a random user reverts
        vm.prank(address(0x1234));
        vm.expectRevert();
        certificates.redeem(tokenIds, msg.sender, data);
        vm.stopPrank();

        vm.prank(msg.sender);
        certificates.redeem(tokenIds, msg.sender, data);

        vm.expectRevert(); // try redeeming again and expect revert
        certificates.redeem(tokenIds, msg.sender, data);

        // confirm msg.sender got the right number of certs
        assertEq(certificates.balanceOf(msg.sender, redeemCertTokenId + 0), 1);
        assertEq(certificates.balanceOf(msg.sender, redeemCertTokenId + 1), 1);
        assertEq(certificates.balanceOf(msg.sender, redeemCertTokenId + 2), 1);
        assertEq(certificates.balanceOf(msg.sender, redeemCertTokenId + 3), 1);
        assertEq(certificates.balanceOf(msg.sender, redeemCertTokenId + 4), 1);
        assertEq(certificates.balanceOf(msg.sender, redeemCertTokenId + 5), 0);

        // // confirm they no longer have the lootbox
        assertEq(lootboxes.balanceOf(msg.sender), 0);

        vm.expectRevert(); // TokenDoesNotExist
        lootboxes.ownerOf(lootboxTokenId);

        vm.stopPrank();
    }

    function testClockworkBlueprintRedeem() public {
        // Tests that the clockwork lootbox blueprint can be redeemed
        address addr2 = address(0xABCD);
        address addr3 = address(0xCCCC);

        uint256 campaignId = 1;
        uint256 certTokenId = 1;

        setUpClockworkBlueprintCampaign();

        // First mint things
        certificates.mint(addr2, certTokenId, 1);
        certificates.setTrait(
            certTokenId,
            traitKey,
            traitValueClockworkBlueprint
        );
        resources.mint(addr2, t2LumberTokenId, 20);
        resources.mint(addr2, t2OreTokenId, 20);
        weth.mint(addr2, 5);

        // Set up data structures for redeem
        uint256[] memory traitRedemptionTokenIds = new uint256[](1);
        traitRedemptionTokenIds[0] = certTokenId;
        bytes memory data = abi.encode(
            campaignId,
            0,
            bytes32(0),
            traitRedemptionTokenIds,
            uint256(0),
            bytes("")
        );

        uint256[] memory tokenIds = new uint256[](4);
        tokenIds[0] = certTokenId;
        tokenIds[1] = t2LumberTokenId;
        tokenIds[2] = t2OreTokenId;
        tokenIds[3] = 1;

        // Redeem
        vm.startPrank(addr2);

        // TODO: see if we can remove the approvals with pre approves
        certificates.setApprovalForAll(address(ships), true);
        resources.setApprovalForAll(address(ships), true);
        cosmetics.setApprovalForAll(address(ships), true);
        weth.approve(address(ships), 999999999);

        ships.redeem(tokenIds, addr2, data);
        vm.stopPrank();

        assertEq(ships.ownerOf(1), addr2);
        assertEq(certificates.balanceOf(addr2, certTokenId), 0);
        assertEq(resources.balanceOf(addr2, t2LumberTokenId), 10);
        assertEq(resources.balanceOf(addr2, t2OreTokenId), 10);
        assertEq(weth.balanceOf(addr2), 0);

        // Verify post redeem state
    }

    function testMint() public {
        lootboxes.mint(msg.sender, 1);
        lootboxes.mint(address(0xABCD), 3);

        assertEq(lootboxes.ownerOf(1), msg.sender);
        assertEq(lootboxes.ownerOf(3), address(0xABCD));
    }

    function testMintAndBurn() public {
        address addr1 = address(0xDCBA);
        address addr2 = address(0xABCD);

        lootboxes.mint(addr1, 1);

        vm.expectRevert();
        lootboxes.burn(100); // Revert because token does not exist

        vm.startPrank(addr2); // https://book.getfoundry.sh/cheatcodes/prank

        vm.expectRevert();
        lootboxes.mint(addr2, 2);

        vm.expectRevert();
        lootboxes.burn(1);

        vm.stopPrank();
    }

    function testCertificateAdminMint() public {
        address addr1 = address(0xDCBA);
        address addr2 = address(0xABCD);

        certificates.adminMint(addr1, 2, 1);
        certificates.adminMint(addr2, 3, 2);

        assertEq(certificates.balanceOf(addr1, 1), 1);
        assertEq(certificates.balanceOf(addr1, 2), 1);
        assertEq(certificates.balanceOf(addr1, 3), 0);
        assertEq(certificates.balanceOf(addr1, 4), 0);
        assertEq(certificates.balanceOf(addr1, 5), 0);
        assertEq(certificates.balanceOf(addr1, 6), 0);

        assertEq(certificates.balanceOf(addr2, 1), 0);
        assertEq(certificates.balanceOf(addr2, 2), 0);
        assertEq(certificates.balanceOf(addr2, 3), 2);
        assertEq(certificates.balanceOf(addr2, 4), 2);
        assertEq(certificates.balanceOf(addr2, 5), 2);
        assertEq(certificates.balanceOf(addr2, 6), 0);
    }

    function testCertificateMintBurnPermissions() public {
        address addr1 = address(0xDCBA);
        address addr2 = address(0xABCD);

        certificates.mint(addr1, 1, 1);
        certificates.adminMint(addr1, 2, 1);
        certificates.burn(addr1, 1, 1);

        vm.startPrank(addr2);

        vm.expectRevert();
        certificates.mint(addr2, 3, 1);

        vm.expectRevert();
        certificates.adminMint(addr2, 4, 1);

        vm.expectRevert();
        certificates.burn(addr2, 3, 1);

        vm.stopPrank();
    }

    function testBatchSetTrait() public {
        address addr1 = address(0xDCBA);

        uint256[] memory tokenIds = new uint256[](10);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;
        tokenIds[3] = 4;
        tokenIds[4] = 5;
        tokenIds[5] = 6;
        tokenIds[6] = 7;
        tokenIds[7] = 8;
        tokenIds[8] = 9;
        tokenIds[9] = 10;

        bytes32[] memory traitValues = new bytes32[](10);
        traitValues[0] = bytes32(uint256(1));
        traitValues[1] = bytes32(uint256(1));
        traitValues[2] = bytes32(uint256(1));
        traitValues[3] = bytes32(uint256(2));
        traitValues[4] = bytes32(uint256(2));
        traitValues[5] = bytes32(uint256(101));
        traitValues[6] = bytes32(uint256(1));
        traitValues[7] = bytes32(uint256(1));
        traitValues[8] = bytes32(uint256(1));
        traitValues[9] = bytes32(uint256(1));

        certificates.batchSetTrait(tokenIds, traitKey, traitValues);

        for (uint i = 0; i < 10; i++) {
            assertEq(
                certificates.getTraitValue(tokenIds[i], traitKey),
                traitValues[i]
            );
        }

        // Verify that reverts on differents sized inputs
        uint256[] memory tokenIds2 = new uint256[](3);
        bytes32[] memory traitValues2 = new bytes32[](2);
        vm.expectRevert();
        certificates.batchSetTrait(tokenIds2, traitKey, traitValues2);

        // Verify that non-owner can't call batchSetTrait
        vm.startPrank(addr1);

        vm.expectRevert();
        certificates.batchSetTrait(tokenIds, traitKey, traitValues);

        vm.stopPrank();
    }

    // TODO:  ships rental test. come back to this.
    // function testShipsRentals() public {
    //     address addr1 = address(0xDCBA);
    //     address addr2 = address(0xABCD);

    //     assertEq(ships.userOf(1), address(0));

    // ships.mint(addr1, 2);
    //     uint64 expires = 2000000000;
    //     ships.setUser(2, addr2, expires);
    //     assertEq(ships.userOf(2), addr2);
    // }

    function testTesting() public {
        // A helper test of things that can be done in tests and how to do them

        // https://book.getfoundry.sh/reference/forge-std/console-log
        console.logAddress(msg.sender);

        // https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert
        vm.expectRevert(bytes("NOT_AUTHORIZED"));
        revert("NOT_AUTHORIZED");
    }
}
