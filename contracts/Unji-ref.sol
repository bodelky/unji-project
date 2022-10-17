// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "hardhat/console.sol";

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

    bytes32 public AIRDROP_ROOT = 0x9d997719c0a5b5f6db9b8ac69a988be57cf324cb9fffd51dc2c37544bb520d65;
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
    // constructor() ERC721A("CryptoUnji", "CUNJI") {
    constructor() ERC721A("CryptoUnji", "CUNJI") {
    }


    ////////////////////
    // MINT FUNCTIONS //
    ////////////////////

    function airDrop(bytes32[] memory proof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, AIRDROP_ROOT, leaf), "Not in Airdrop");
        require(!airdropClaimed[msg.sender], "Already Claimed");
        _safeMint(msg.sender, 1);
        airdropClaimed[msg.sender] = true;
        emit UnjiMinted(msg.sender, 1);
    }

    function whiteListMint(bytes32[] memory proof, uint256 quantity) external inMintPhase(MintPhase.WHITELIST_SALE){
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, WHITELIST_ROOT, leaf), "Not in Whitelist");
        _safeMint(msg.sender, quantity);
        emit UnjiMinted(msg.sender, quantity);
    }


    function mintRef(uint256 quantity, address refAddress) external payable inMintPhase(MintPhase.PUBLIC_SALE) {
        require(balanceOf(refAddress) > 0, "This referral has not hold Unji yet!");
        uint256 price = (MINT_PRICE_PUBLIC * quantity * 95) / 100;
        uint256 fee = (MINT_PRICE_PUBLIC * quantity * 5) / 100;
        require(msg.value >= price);
        _safeMint(msg.sender, quantity);
        emit UnjiMinted(msg.sender, quantity);
        payable(refAddress).transfer(fee);
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
        payable(owner()).transfer(address(this).balance);
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
 * Transfer failed
 */
error TransferFailed();


/**
 * Function not implemented
 */
error NotImplemented();
