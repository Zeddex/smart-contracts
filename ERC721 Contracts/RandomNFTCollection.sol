// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// NFT collection with random ID generation
contract RandomNFTCollection is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    string baseURI = "ipfs://ipfsAddress/";
    uint private _maxSupply = 10;
    uint256 public cost = 0.1 ether;
    uint256 public currentSupply = 0;
    Counters.Counter private _tokenCount;
    mapping(uint256 => uint256) private tokenMatrix;

    constructor() ERC721("Random Collection", "RND") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
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

    function totalSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }

    function tokenCount() private view returns (uint256) {
        return _tokenCount.current();
    }

    function availableTokenCount() public view returns (uint256) {
        return totalSupply() - tokenCount();
    }

    function nextToken() private returns (uint256) {
        uint256 token = _tokenCount.current();

        _tokenCount.increment();

        return token;
    }

    function nextTokenRandom() private ensureAvailability returns (uint256) {
        uint256 maxIndex = totalSupply() - tokenCount();
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
        nextToken();

        return value + 1;
    }

    modifier ensureAvailability() {
        require(availableTokenCount() > 0, "No more tokens available");
        _;
    }

    function mint() public payable {
        require(tokenCount() + 1 <= totalSupply(), "You cannot mint more than maximum supply");
        require(availableTokenCount() - 1 >= 0, "You cannot mint more than available token count"); 
        require( tx.origin == msg.sender, "Cannot mint through a custom contract");

        if (msg.sender != owner()) {  
          require(msg.value >= cost, "Insufficient funds!");
        }
      
        uint256 tokenId = nextTokenRandom();

        _safeMint(msg.sender, tokenId);

        currentSupply++;
    }

    function mintToAddress(address to) public onlyOwner {
        require(tokenCount() + 1 <= totalSupply(), "You cannot mint more than maximum supply");
        require(availableTokenCount() - 1 >= 0, "You cannot mint more than available token count"); 
      
        uint256 tokenId = nextTokenRandom();

        _safeMint(to, tokenId);

        currentSupply++;
    }
    
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }
  
    function withdraw() public payable onlyOwner {
        (bool sent, ) = payable(owner()).call{value: address(this).balance}("");
        require(sent, "Transfer failed");
    }
}