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

// contract ERC7498_SimpleRedeem is BaseRedeemablesTest, CNCContractScript {
contract LootboxTests is Test {
    ERC721ShipyardRedeemableMintable lootboxes;
    ERC1155ShipyardRedeemableMintable certificates;
    ERC1155ShipyardRedeemableMintable resources;
    ERC721ShipyardRedeemableMintableRentable ships;
    ERC721ShipyardRedeemableMintable cosmetics;

    uint32 campaignStartTime = 0; //  seconds since epoch
    uint32 campaignEndTime = 2000000000; // seconds since epoch
    uint32 maxCampaignRedemptions = 1_000_000_000;

    function setUp() public virtual {
        // super.setUp();

        lootboxes = new ERC721ShipyardRedeemableMintable(
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
            startTime: campaignStartTime,
            endTime: campaignEndTime,
            maxCampaignRedemptions: maxCampaignRedemptions,
            manager: msg.sender
        });

        uint campaignId = certificates.createCampaign(params, "uri://");
        return campaignId;
    }

    function testLootboxCertificatesRedeem() public {
        address addr1 = address(0xDCBA);
        address addr2 = address(0xABCD);

        setUpCertificatesCampaign();

        // mint the user a lootbox
        uint campaignId = 1;
        uint tokenId = 3;

        lootboxes.mint(msg.sender, tokenId);

        assertEq(lootboxes.ownerOf(tokenId), msg.sender); // confirm they have the lootbox
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

        lootboxes.setPreapprovedAddress(address(certificates));

        vm.prank(msg.sender);

        // lootboxes.setApprovalForAll(address(certificates), true);
        certificates.redeem(tokenIds, msg.sender, data);

        vm.expectRevert(); // try redeeming again and expect revert
        certificates.redeem(tokenIds, msg.sender, data);

        // // confirm msg.sender got the right number of certs
        assertEq(certificates.balanceOf(msg.sender, 1), 1);
        assertEq(certificates.balanceOf(msg.sender, 2), 1);
        assertEq(certificates.balanceOf(msg.sender, 3), 1);
        assertEq(certificates.balanceOf(msg.sender, 4), 1);
        assertEq(certificates.balanceOf(msg.sender, 5), 1);
        assertEq(certificates.balanceOf(msg.sender, 6), 0);

        // // confirm they no longer have the lootbox
        assertEq(lootboxes.balanceOf(msg.sender), 0);
        vm.stopPrank();
    }

    function testTesting() public {
        // A helper test of things that can be done in tests and how to do them

        // https://book.getfoundry.sh/reference/forge-std/console-log
        console.logAddress(msg.sender);

        // https://book.getfoundry.sh/cheatcodes/expect-revert?highlight=expectRevert
        vm.expectRevert(bytes("NOT_AUTHORIZED"));
        revert("NOT_AUTHORIZED");
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
        lootboxes.burn(1); // THIS SHOULD REVERT (but isn't)

        vm.stopPrank();
    }

    // TODO:  ships rental test. come back to this.
    // function testShipsRentals() public {
    //     address addr1 = address(0xDCBA);
    //     address addr2 = address(0xABCD);

    //     assertEq(ships.userOf(1), address(0));

    //     ships.mint(addr1, 2);
    //     uint64 expires = 2000000000;
    //     ships.setUser(2, addr2, expires);
    //     assertEq(ships.userOf(2), addr2);
    // }
}
