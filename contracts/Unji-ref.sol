// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract CryptoUnji is ERC721A, Ownable, Pausable, ReentrancyGuard, PaymentSplitter {
    enum MintPhase {
        NONE,
        WHITELIST_SALE,
        PUBLIC_SALE
    }

    MintPhase public mintPhase = MintPhase.NONE;
    uint16 public constant TOTAL_COLLECTION_SIZE = 7777;
    uint16 public constant WHITELIST_COLLECTION_SIZE = 1000;
    uint16 public constant MAX_AIRDROP = 777;

    uint256 public constant MINT_PRICE_PUBLIC = 5 ether; // 0.05
    uint256 public constant MINT_PRICE_WHITELIST = 0.025 ether; // 0.025

    mapping(address => bool) public whitelist;
    bool public whitelistActive;
    uint256 public whitelistCounter;

    string private baseURI;



    mapping(uint256 => address) public referral;
    // ref[]


    function mintRef(uint256 quantity, address refAddress) external payable inMintPhase(MintPhase.PUBLIC_SALE) {
        require(balanceOf(refAddress) > 0, "This referral has not hold Unji yet!");
        uint256 price = (MINT_PRICE_PUBLIC * quantity * 95) / 100;
        uint256 fee = (MINT_PRICE_PUBLIC * quantity * 5) / 100;
        require(msg.value >= price);
        _safeMint(msg.sender, quantity);
        payable(refAddress).transfer(fee);
    }


    ////////////////////////
    // MODIFIER FUNCTIONS //
    ////////////////////////

    modifier mintCondition(uint256 quantity) {
        require(totalSupply() < TOTAL_COLLECTION_SIZE, "NFT Already sold out");
        require(totalSupply() + quantity <= TOTAL_COLLECTION_SIZE, "Cannot mint over supply");
        _;
    }

    modifier whitelistCondition(uint256 quantity) {
        require(whitelistCounter < WHITELIST_COLLECTION_SIZE, "Whitelist NFT already Sold out");
        require(whitelistCounter + quantity <= WHITELIST_COLLECTION_SIZE, "Cannot mint over whitelist supply");
        _;
    }

    /*
     */
    modifier isWhitelistActive() {
        require(whitelistActive, "Not in whitelist period");
        _;
    }

    modifier inMintPhase(MintPhase _mintPhase) {
        require(mintPhase == _mintPhase, "Not correct mint phase");
        _;
    }

    /*
     */
    // constructor() ERC721A("CryptoUnji", "CUNJI") {
    constructor(address[] memory payee, uint256[] memory share) ERC721A("CryptoUnji", "CUNJI") PaymentSplitter(payee, share){
        whitelistActive = false;
        whitelistCounter = 0;
    }

    /////////////////////////
    // WHITELIST FUNCTIONS //
    /////////////////////////

    /*
     */
    function addWhitelist() public isWhitelistActive {
        whitelist[msg.sender] = true;
    }

    /*
    */
    function removeWhitelist(address[] memory addrs) public onlyOwner {
        require(addrs.length > 0, "Please input address");
        for (uint i = 0; i < addrs.length; i++){
            whitelist[addrs[i]] = false;
        }
    }

    ////////////////////
    // MINT FUNCTIONS //
    ////////////////////

    function whitelistMint(uint16 quantity) external payable nonReentrant inMintPhase(MintPhase.WHITELIST_SALE) whitelistCondition(quantity){
        require(whitelist[msg.sender], "You are not in whitelist!!");
        uint256 price = quantity * MINT_PRICE_WHITELIST;
        require(msg.value >= price, "Insufficient value");
        _safeMint(msg.sender, quantity);
        whitelistCounter += quantity;
    }

    /**
     * @notice Mint a quantity of tokens during public mint phase
     * @param quantity Number of tokens to mint
     */
    function mint(uint16 quantity) external payable nonReentrant inMintPhase(MintPhase.PUBLIC_SALE) mintCondition(quantity) {
        uint256 price = quantity * MINT_PRICE_PUBLIC;
        require(msg.value >= price, "Insufficient value");

        _safeMint(msg.sender, quantity);
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
    receive() external payable override {
        emit PaymentReceived(_msgSender(), msg.value);
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
