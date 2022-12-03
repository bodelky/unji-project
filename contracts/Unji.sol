// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

//            _  .-')                 _ (`-.  .-') _                                  .-') _
//           ( \( -O )               ( (OO  )(  OO) )                                ( OO ) )
//    .-----. ,------.   ,--.   ,--._.`     \/     '._  .-'),-----.  ,--. ,--.   ,--./ ,--,'      ,--.  ,-.-')
//   '  .--./ |   /`. '   \  `.'  /(__...--''|'--...__)( OO'  .-.  ' |  | |  |   |   \ |  |\  .-')| ,|  |  |OO)
//   |  |('-. |  /  | | .-')     /  |  /  | |'--.  .--'/   |  | |  | |  | | .-') |    \|  | )( OO |(_|  |  |  \
//  /_) |OO  )|  |_.' |(OO  \   /   |  |_.' |   |  |   \_) |  |\|  | |  |_|( OO )|  .     |/ | `-'|  |  |  |(_/
//  ||  |`-'| |  .  '.' |   /  /\_  |  .___.'   |  |     \ |  | |  | |  | | `-' /|  |\    |  ,--. |  | ,|  |_.'
// (_'  '--'\ |  |\  \  `-./  /.__) |  |        |  |      `'  '-'  '('  '-'(_.-' |  | \   |  |  '-'  /(_|  |
//    `-----' `--' '--'   `--'      `--'        `--'        `-----'   `-----'    `--'  `--'   `-----'   `--'

contract CryptoUnji is ERC721A, Ownable, Pausable {
    enum MintPhase {
        NONE,
        WHITELIST_SALE,
        PUBLIC_SALE
    }

    MintPhase public mintPhase = MintPhase.NONE;
    uint16 public constant TOTAL_COLLECTION_SIZE = 7777;
    uint16 public constant WHITELIST_MAX = 1500;
    uint16 public constant AIRDROP_MAX = 77;

    uint256 public constant MINT_PRICE_PUBLIC = 0.05 ether; // 0.05
    uint256 public constant MINT_PRICE_WHITELIST = 0.025 ether; // 0.025

    uint16 public airdropCounter = 0;
    uint16 public whitelistCounter = 0;

    string private baseURI;

    bytes32 public WHITELIST_ROOT;

    mapping(address => bool) public airdropClaimed;

    /////////////////////
    // EVENT FUNCTIONS //
    /////////////////////

    event UnjiMinted(address to, uint16 quantity);
    event Rewarded(uint256 winnerID, address winnerAddress);

    ////////////////////////
    // MODIFIER FUNCTIONS //
    ////////////////////////

    modifier inMintPhase(MintPhase _mintPhase) {
        require(mintPhase == _mintPhase, "Not correct mint phase");
        _;
    }

    /*
     */
    constructor(string memory bURI, bytes32 root)
        ERC721A("CryptoUnji", "CUNJI")
    {
        baseURI = bURI;
        WHITELIST_ROOT = root;
        _safeMint(msg.sender, 6);
    }

    ////////////////////
    // MINT FUNCTIONS //
    ////////////////////

    function whiteListMint(bytes32[] memory proof, uint16 quantity)
        external
        payable
        inMintPhase(MintPhase.WHITELIST_SALE)
    {
        require(WHITELIST_ROOT != bytes32(0), "WHITELIST IS NOT SET YET");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(proof, WHITELIST_ROOT, leaf),
            "Not in Whitelist"
        );
        uint256 price = quantity * MINT_PRICE_WHITELIST;

        require(msg.value >= price, "Insufficient value");
        require(
            whitelistCounter + quantity <= WHITELIST_MAX,
            "WHITELIST ALREADY SOLD OUT"
        );
        whitelistCounter += quantity;
        _safeMint(msg.sender, quantity);
        emit UnjiMinted(msg.sender, quantity);
    }

    function mint(uint16 quantity)
        external
        payable
        inMintPhase(MintPhase.PUBLIC_SALE)
    {
        require(totalSupply() < TOTAL_COLLECTION_SIZE, "NFT Already sold out");
        require(
            totalSupply() + quantity <= TOTAL_COLLECTION_SIZE,
            "Cannot mint over supply"
        );

        uint256 price = quantity * MINT_PRICE_PUBLIC;
        require(msg.value >= price, "Insufficient value");
        _safeMint(msg.sender, quantity);
        emit UnjiMinted(msg.sender, quantity);
    }

    function airDrop(address to, uint16 quantity) external onlyOwner {
        require(
            airdropCounter + quantity <= AIRDROP_MAX,
            "AIRDROP ALREADY SOLD OUT"
        );
        airdropCounter += quantity;
        _safeMint(to, quantity);
        emit UnjiMinted(to, quantity);
    }

    //////////////////////
    // SETTER FUNCTIONS //
    //////////////////////

    function setMintPhase(MintPhase _mintPhase) external onlyOwner {
        mintPhase = _mintPhase;
    }

    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    function setWhitelistRoot(bytes32 newRoot) external onlyOwner {
        WHITELIST_ROOT = newRoot;
    }

    //////////////////////
    // GETTER FUNCTIONS //
    //////////////////////

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /////////////////////
    // ADMIN FUNCTIONS //
    /////////////////////

    function rewardDrop() external onlyOwner {
        require(msg.sender == tx.origin, "You are not human");
        uint256 winnerID = (block.timestamp % 10) + 5;
        address winnerAddress = this.ownerOf(winnerID);
        payable(address(winnerAddress)).transfer(2 ether);
        emit Rewarded(winnerID, winnerAddress);
    }

    function bulkTransfer(
        address from,
        address to,
        uint256[] memory tokenIds
    ) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom((from), to, tokenIds[i]);
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 0;
    }

    /**
     * @notice Prevent accidental ETH transfer
     */
    fallback() external payable {
        revert NotImplemented();
    }

    /**
     * @notice Prevent accidental ETH transfer
     */
    receive() external payable {
        revert NotImplemented();
    }
}

/**
 * Transfer failed
 */
error TransferFailed();

/**
 * Function not implemented
 */
error NotImplemented();
