// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CryptoUnji is ERC721A, Ownable, Pausable, ReentrancyGuard {
    enum MintPhase {
        NONE,
        WHITELIST_SALE,
        PUBLIC_SALE
    }


    uint16 public constant TOTAL_COLLECTION_SIZE = 5500;
    uint16 public constant WHITELIST_COLLECTION_SIZE = 1000;

    // uint8 public constant MAX_PER_ADDRESS_PUBLIC = 10;
    uint256 public constant MINT_PRICE_PUBLIC = 0.05 ether;
    uint256 public constant MINT_PRICE_WHITELIST = 0.025 ether;

    mapping(address => bool) public whitelist;
    bool public whitelistActive;


    ////////////////////////
    // XXXXXXXX FUNCTIONS //
    ////////////////////////

    /*
     */
    function addWhitelist() public isWhitelistActive {
        whitelist[msg.sender] = true;
    }

    /*
    */
    function removeWhitelist(address[] memory addrs) public onlyOwner {
        if(addrs.length > 0) {
            revert IncorrectAddress();
        }
        for (uint i = 0; i < addrs.length; i++){
            whitelist[addrs[i]] = false;
        }
    }

    string private baseURI;
    string public provenanceHash;
    uint256 public initialMetadataSequenceIndex;
    MintPhase public mintPhase = MintPhase.NONE;
    mapping(address => uint8) public maxAllowlistRedemptions;

    ////////////////////////
    // MODIFIER FUNCTIONS //
    ////////////////////////

    /*
     */
    modifier isWhitelistActive() {
        require(whitelistActive, "Not in whitelist period");
        _;
    }

    modifier inMintPhase(MintPhase _mintPhase) {
        if (mintPhase != _mintPhase) {
            revert IncorrectMintPhase();
        }
        _;
    }

    // /**
    //  * @param _provenanceHash provenance record
    //  */
    // constructor(string memory _provenanceHash) ERC721A("CryptoUnji", "CUNJI") {
    constructor() ERC721A("CryptoUnji", "CUNJI") {
        whitelistActive = false;
        // provenanceHash = _provenanceHash;
    }

    ////////////////////
    // MINT FUNCTIONS //
    ////////////////////

    function whitelistMint(uint16 quantity) external payable nonReentrant inMintPhase(MintPhase.WHITELIST_SALE) {
        require(whitelist[msg.sender], "You are not in whitelist!!");
        require(msg.value >= MINT_PRICE_WHITELIST, "Insufficient value");
        _safeMint(msg.sender, quantity);
    }

    /**
     * @notice Mint a quantity of tokens during public mint phase
     * @param _quantity Number of tokens to mint
     */
    function mint(uint16 _quantity) external payable nonReentrant inMintPhase(MintPhase.PUBLIC_SALE){
        require(msg.value >= MINT_PRICE_PUBLIC, "Insufficient value");

        _safeMint(msg.sender, _quantity);
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
    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseURI = _baseTokenURI;
    }

    function setWhitelist(bool _whitelist) public onlyOwner {
        whitelistActive = _whitelist;
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

    //////////////////////
    // HELPER FUNCTIONS //
    //////////////////////


    /////////////////////
    // ADMIN FUNCTIONS //
    /////////////////////

    /**
     * @notice Mint a quantity of tokens to the contract owners address
     * @notice Use restricted to contract owner
     * @param _quantity Number of tokens to mint
     * @dev Must be executed in `MintPhase.NONE` (i.e., before allowlist or public mint begins)
     * @dev Minting in batches will not help prevent overly expensive transfer fees, since
     * token ids are sequential and dev minting occurs before allowlist and public minting.
     * See https://chiru-labs.github.io/ERC721A/#/tips?id=batch-size
     */
    function devMint(uint256 _quantity)
        external
        onlyOwner
    {
        if (totalSupply() + _quantity > TOTAL_COLLECTION_SIZE) {
            revert InsufficientSupply();
        }

        _safeMint(owner(), _quantity);
    }

    /*
    */
    function bulkTransfer(address from, address to, uint256[] memory tokenIds) public onlyOwner {
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
        (bool success, ) = owner().call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
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
* Incorrect input addresses
*/
error IncorrectAddress();


/**
 * Incorrect mint phase for action
 */
error IncorrectMintPhase();

/**
 * Incorrect payment amount
 */
error IncorrectPayment();

/**
 * Insufficient supply for action
 */
error InsufficientSupply();

/**
 * Not allowlisted
 */
error NotAllowlisted();

/**
 * Exceeds max allocation for public sale
 */
error ExceedsPublicMaxAllocation();

/**
 * Exceeds max allocation for allowlist sale
 */
error ExceedsAllowlistMaxAllocation();

/**
 * Public mint price not set
 */
error PublicMintPriceNotSet();

/**
 * Transfer failed
 */
error TransferFailed();

/**
 * Bad arguments
 */
error BadArguments();

/**
 * Function not implemented
 */
error NotImplemented();
