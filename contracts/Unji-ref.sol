// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "hardhat/console.sol";

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

    uint256 public constant MINT_PRICE_PUBLIC = 0.05 ether; // 0.05
    uint256 public constant MINT_PRICE_WHITELIST = 0.025 ether; // 0.025


    string private baseURI;

    bytes32 public WHITELIST_ROOT = 0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c;
    mapping(address => bool) public airdropClaimed;


    /////////////////////
    // EVENT FUNCTIONS //
    /////////////////////

    event UnjiMinted(address to, uint256 quantity);

    ////////////////////////
    // MODIFIER FUNCTIONS //
    ////////////////////////

    modifier mintCondition(uint256 quantity) {
        require(totalSupply() < TOTAL_COLLECTION_SIZE, "NFT Already sold out");
        require(totalSupply() + quantity <= TOTAL_COLLECTION_SIZE, "Cannot mint over supply");
        _;
    }


    modifier inMintPhase(MintPhase _mintPhase) {
        require(mintPhase == _mintPhase, "Not correct mint phase");
        _;
    }

    /*
     */
    constructor() ERC721A("CryptoUnji", "CUNJI") {
        _safeMint(msg.sender, 6);
    }


    ////////////////////
    // MINT FUNCTIONS //
    ////////////////////

    /**
     * @notice Mint a quantity of tokens during whitelist mint phase
     * @param proof Merkle proof that you are in whitelist
     * @param quantity Number of tokens to mint
     */
    function whiteListMint(bytes32[] memory proof, uint256 quantity) external payable inMintPhase(MintPhase.WHITELIST_SALE){
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, WHITELIST_ROOT, leaf), "Not in Whitelist");
        uint256 price = quantity * MINT_PRICE_WHITELIST;
        require(msg.value >= price, "Insufficient value");
        _safeMint(msg.sender, quantity);
        emit UnjiMinted(msg.sender, quantity);
    }

    /**
     * @notice Mint a quantity of tokens during public mint phase
     * @param quantity Number of tokens to mint
     */
    function mint(uint16 quantity) external payable inMintPhase(MintPhase.PUBLIC_SALE) mintCondition(quantity) {
        uint256 price = quantity * MINT_PRICE_PUBLIC;
        require(msg.value >= price, "Insufficient value");
        _safeMint(msg.sender, quantity);
        emit UnjiMinted(msg.sender, quantity);
    }

    function airDrop(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
        emit UnjiMinted(to, quantity);
    }

    //////////////////////
    // SETTER FUNCTIONS //
    //////////////////////

    /**
     * @notice Set the mint phase
     * @notice Use restricted to contract owner
     * @param _mintPhase New mint phase
     */
    function setMintPhase(MintPhase _mintPhase) external onlyOwner {
        mintPhase = _mintPhase;
    }

    /**
     * @notice Set the contract base token uri
     * @notice Use restricted to contract owner
     * @param _baseTokenURI New base token uri
     */
    function setBaseURI(string memory _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    function setAirdropRoot(bytes32 newRoot) external onlyOwner {
        AIRDROP_ROOT = newRoot;
    }

    function setWhitelistRoot(bytes32 newRoot) external onlyOwner {
        WHITELIST_ROOT = newRoot;
    }


    //////////////////////
    // GETTER FUNCTIONS //
    //////////////////////

    /**
     * @return Current base token uri
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /////////////////////
    // ADMIN FUNCTIONS //
    /////////////////////

    /*
    */
    function bulkTransfer(address from, address to, uint256[] memory tokenIds) public {
        for(uint i = 0; i < tokenIds.length ; i++ ) {
            safeTransferFrom((from), to, tokenIds[i]);
        }
    }


    /**
     * @notice Withdraw all funds to the contract owners address
     * @notice Use restricted to contract owner
     * @dev `transfer` and `send` assume constant gas prices. This function
     * is onlyOwner, so we accept the reentrancy risk that `.call.value` carries.
     */
    function withdraw() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
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
