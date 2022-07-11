// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// NFT collection with random ID generation
contract RandomNFTCollection is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenCount;
    Counters.Counter private _currentSupply;
    mapping(uint256 => uint256) private tokenMatrix;

    string baseURI = "ipfs://ipfsAddress/";
    uint public maxSupply = 10;
    uint256 public cost = 0.1 ether;
    uint256 private premint = 3;
    uint256 private startRndCount = premint + 1;

    constructor() ERC721("Random Collection", "RND") {
        // mint some tokens to the owner on deployment
        for (uint i = 1; i <= premint; i++) {
            _safeMint(msg.sender, i);

            // update random
            uint256 maxIndex = maxSupply - tokenCount();
            tokenMatrix[i] = maxIndex - 1;

            _tokenCount.increment();
            currentSupplyIncrement();
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
      }

    function totalSupply() public view returns (uint256) {
        return _currentSupply.current();
    }

    function tokenURI(uint256 tokenId)
      public
      view
      virtual
      override
      returns (string memory)
    {
        require(
          _exists(tokenId),
          "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();

        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
            : "";
    }

    function tokenCount() private view returns (uint256) {
        return _tokenCount.current();
    }

    function currentSupplyIncrement() private {
        _currentSupply.increment();
    }

    function availableTokenCount() public view returns (uint256) {
        return maxSupply - tokenCount();
    }

    function nextTokenRandom() private ensureAvailability returns (uint256) {
        uint256 maxIndex = maxSupply - tokenCount();
        uint256 random = uint256(keccak256(
            abi.encodePacked(
                msg.sender,
                block.coinbase,
                block.difficulty,
                block.gaslimit,
                block.timestamp
            )
        )) % maxIndex;

        uint256 value = 0;

        if (tokenMatrix[random] == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = tokenMatrix[random];
        }

        // If the last available tokenID is still unused...
        if (tokenMatrix[maxIndex - 1] == 0) {
            // ...store that ID in the current matrix position.
            tokenMatrix[random] = maxIndex - 1;
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            tokenMatrix[random] = tokenMatrix[maxIndex - 1];
        }

        // Increment counts
        _tokenCount.increment();

        return value + startRndCount;
    }

    function mint() public payable mintRequirements {
        require(tokenCount() + 1 <= maxSupply, "You cannot mint more than maximum supply");
        require(availableTokenCount() - 1 >= 0, "You cannot mint more than available token count"); 
        require( tx.origin == msg.sender, "Cannot mint through a custom contract");

        if (msg.sender != owner()) {  
          require(msg.value >= cost, "Insufficient funds!");
        }
      
        uint256 tokenId = nextTokenRandom();

        _safeMint(msg.sender, tokenId);

        currentSupplyIncrement();
    }

    function mintToAddress(address to) public onlyOwner mintRequirements {
        require(tokenCount() + 1 <= maxSupply, "You cannot mint more than maximum supply");
        require(availableTokenCount() - 1 >= 0, "You cannot mint more than available token count"); 
      
        uint256 tokenId = nextTokenRandom();

        _safeMint(to, tokenId);

       currentSupplyIncrement();
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
  
    function withdraw() public payable onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Transfer failed");
    }

    modifier ensureAvailability() {
        require(availableTokenCount() > 0, "No more tokens available");
        _;
    }

    modifier mintRequirements() {
        require(tokenCount() + 1 <= maxSupply, "You cannot mint more than maximum supply");
        require(availableTokenCount() - 1 >= 0, "You cannot mint more than available token count"); 
        require( tx.origin == msg.sender, "Cannot mint through a custom contract");
        _;
    }
}