// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract KaijuKongz is ERC721A, Ownable, AccessControlEnumerable {
    uint256 constant public legendarySupply = 9;
    uint256 constant public teamSupply = 30;

    uint256 public maxTotalSupply = 3333;
    uint256 public pricePerToken = 0.065 ether;
    uint256 public tokensBurned = 0;
    bool public promoTokensMinted = false;
    bool public tradeActive = false;
    uint256 public deployedTime;
    
    enum SaleState{ CLOSED, PRIVATE, PUBLIC }
    SaleState public saleState = SaleState.CLOSED;

    bytes32 private merkleRootGroup1;
    bytes32 private merkleRootGroup2;

    uint8 private maxTokenWlGroup1 = 1;
    uint8 private maxTokenWlGroup2 = 2;
    uint8 private maxTokenPublic = 5;

    uint256 private disableBurnTime = 518400;

    mapping(address => uint256) presaleMinted;
    mapping(address => uint256) publicMinted;

    string _baseTokenURI;
    address _burnerAddress;
 

    constructor() ERC721A("KaijuKongz", "Kai") {
      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
      deployedTime = block.timestamp;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) public override {
      require(tradeActive, "Trade is not active");
      super.safeTransferFrom(_from, _to, _tokenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
      require(tradeActive, "Trade is not active");
      super.safeTransferFrom(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
      require(tradeActive, "Trade is not active");
      super.transferFrom(_from, _to, _tokenId);
    }

    function setTradeState(bool tradeState) public {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot set trade state");
      tradeActive = tradeState;
    }

    function setPrice(uint256 newPrice) public {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot set price");
      pricePerToken = newPrice;
    }

    function withdraw() public onlyOwner {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot withdraw");
        payable(owner()).transfer(address(this).balance);
    }

    function setSaleState(SaleState newState) public {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot alter sale state");
      saleState = newState;
    }

    function setMerkleRoot(bytes32 newRootGroup1, bytes32 newRootGroup2) public {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot set merkle root");
      merkleRootGroup1 = newRootGroup1;
      merkleRootGroup2 = newRootGroup2;
    }

    function promoMint() public onlyOwner {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Cannot mint team tokens");
      require(!promoTokensMinted, "Promo tokens have already been minted");
      _safeMint(owner(), legendarySupply + teamSupply);
      promoTokensMinted = true;
    }

    function presale(uint256 amount, bytes32[] calldata proof) public payable {
      require (saleState == SaleState.PRIVATE, "Sale state should be private");
      require(totalSupply() < maxTotalSupply, "Max supply reached");
      require(promoTokensMinted, "Promo tokens should be minted in advance");
      bool isValidGroup1 = MerkleProof.verify(proof, merkleRootGroup1, keccak256(abi.encodePacked(msg.sender)));
      bool isValidGroup2 = MerkleProof.verify(proof, merkleRootGroup2, keccak256(abi.encodePacked(msg.sender)));
      require(isValidGroup1 || isValidGroup2, "You are not in the valid whitelist");

      uint256 amountAllowed = isValidGroup1 ? maxTokenWlGroup1 : maxTokenWlGroup2;
      require(amount + presaleMinted[msg.sender] <= amountAllowed, "Your token amount reached out max");
      require(presaleMinted[msg.sender] < amountAllowed, "You've already minted all");
      uint256 amountToPay = amount * pricePerToken;
      require(amountToPay <= msg.value, "Provided not enough Ether for purchase");
      presaleMinted[msg.sender] += amount;
      _safeMint(_msgSender(), amount);
    }

    function publicsale(uint256 amount) public payable {
    //   require (saleState == SaleState.PUBLIC, "Sale state should be public");
    //   require(promoTokensMinted, "Promo tokens should be minted in advance");
      require(totalSupply() < maxTotalSupply, "Max supply reached");
      require(amount + publicMinted[msg.sender] <= maxTokenPublic, "Your token amount reached out max");
      uint256 amountToPay = amount * pricePerToken;
      require(amountToPay <= msg.value, "Provided not enough Ether for purchase");
      publicMinted[msg.sender] += amount;
      _safeMint(_msgSender(), amount);
    }

    function burnMany(uint256[] calldata tokenIds) public {
      require(_msgSender() == _burnerAddress, "Only burner can burn tokens");
      uint256 nowTime = block.timestamp;
      require(nowTime - deployedTime <= disableBurnTime, "Burn is available only for 6 days");
      for (uint256 i; i < tokenIds.length; i++) {
        _burn(tokenIds[i]);
      }
      maxTotalSupply -= tokenIds.length;
      tokensBurned += tokenIds.length;
    }

    function setBurnerAddress(address burnerAddress) public {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller cannot set burn address");
      _burnerAddress = burnerAddress;
    }

    function _baseURI() internal view virtual override returns (string memory) {
      return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControlEnumerable) returns (bool) {
      return super.supportsInterface(interfaceId);
    }
}