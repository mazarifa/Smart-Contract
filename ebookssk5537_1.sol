// Modified from Source Contract: IPTM_BlockchainCertificate.sol
// Link to Reference Contract: https://github.com/iexplotech/SmartContract/blob/master/IPTM_BlockchainCertificate.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

contract eBPBM {
    address payable internal owner; 
   
    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
  
    function getOwner() public view returns (address) {
        return owner;
    }

    constructor() {
        owner = msg.sender;
    }
}

contract Library {
    function concat5StrPadding(string memory s1, string memory s2, string memory s3, string memory s4, string memory s5) 
        internal pure returns (string memory) {
        return string(abi.encodePacked(s1, "::", s2, "::", s3, "::", s4, "::", s5));
    }

    function concat2Str(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    function strCompare(string memory _a, string memory _b) internal pure returns (int _returnCode) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) {
            minLength = b.length;
        }
        for (uint i = 0; i < minLength; i ++) {
            if (a[i] < b[i]) {
                return -1;
            } else if (a[i] > b[i]) {
                return 1;
            }
        }
        if (a.length < b.length) {
            return -1;
        } else if (a.length > b.length) {
            return 1;
        } else {
            return 0;
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "Overflow Add Operation");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "Underflow Subtraction Operation");
        c = a - b;
    }

    struct slice {
        uint _len;
        uint _ptr;
    }
}

contract ebookstore is eBPBM, Library {

    struct Ebook {

        string data;
        uint256 timestamp;
        string prev;  // Use for backward travesal searching Ebook
        string next;  // Use for forward travesal searching Ebook

    }

    //mapping(uint256 => Ebook) private myBooks;
    mapping(string => Ebook) internal mapBooks;  // LinkedList of Certificates: string ebookNo => struct Ebook
    string internal tempFirstEbookNo;  // Pointer to the first added EbookNo, use for forward traversal searching Ebook
    string internal tempLatestEbookNo;  // Pointer to the latest added EbookNo, use for backward traversal searching Ebook
    uint256 internal totalEbook;

   constructor() {
      owner = msg.sender;
      tempFirstEbookNo = "";
      tempLatestEbookNo = "";
      totalEbook = 0;
   }

    function addEbook(string memory _ebookNo, string memory _data) 
    public onlyOwner returns (bool Status) {
            
         // Check EbookNo existent, true if EbookNo existed
        if(isValidEbook(_ebookNo) == true) {
            return (false);  // may use revert()
        }

        mapBooks[_ebookNo].data = _data;
        mapBooks[_ebookNo].timestamp = block.timestamp;

        mapBooks[_ebookNo].next = "";  // next always empty until new added ebook triggered. Latest added ebook will update previous ebook next
        
        if(totalEbook == 0) {  // Will add the first ebook into mapBooks
            mapBooks[_ebookNo].prev = "";  // The first ebookadded always prev empty
            tempFirstEbookNo = _ebookNo;  // Pointer to the first added EbookNo, use for forward travesal searching Cert
        } else {
            mapBooks[_ebookNo].prev = tempLatestEbookNo;  // Add previous, use for backward travesal searching Cert
            mapBooks[tempLatestEbookNo].next = _ebookNo;  // Update previous ebook with next EbookNo, use for forward travesal searching Cert
            
        }

        tempLatestEbookNo = _ebookNo; // Set existing Ebook No as reference for future new addEbook()
        totalEbook = add(totalEbook, 1); // increase ebook counter

        return true;
    }

    function readEbook(string memory _ebookNo) public view returns (
        string memory EbookIndex, string memory Data, uint256 Timestamp) {
        
        if(isValidEbook(_ebookNo) == false)
            return (_ebookNo, "", 0);
        else 
            return (_ebookNo, mapBooks[_ebookNo].data, mapBooks[_ebookNo].timestamp);
    }

    function traversalEbook(string memory _ebookNo) public view onlyOwner returns (
        string memory EbookIndex, string memory Data, uint256 Timestamp, string memory PrevEbookNo, string memory NextEbookNo) {
        
        if(isValidEbook(_ebookNo) == false)
            return (_ebookNo, "", 0, "", "");
        else 
            return (_ebookNo, mapBooks[_ebookNo].data, mapBooks[_ebookNo].timestamp, mapBooks[_ebookNo].prev, mapBooks[_ebookNo].next);
    }

    function isValidEbook(string memory _ebookNo) public view returns (bool Status) {
         
        if(mapBooks[_ebookNo].timestamp == 0)  // 0 is empty
            return (false);
        else
            return (true);
    }

    function updateEbook(string memory _ebookNo, string memory _data) 
    public onlyOwner returns (bool Status) {
            
        if(isValidEbook(_ebookNo) == false) {
            return (false); // may use revert()
        }

        mapBooks[_ebookNo].data = _data;
        mapBooks[_ebookNo].timestamp = block.timestamp;        
        return true;
    }

    function deleteEbook(string memory _ebookNo) public onlyOwner returns (bool Status) {
         
        // Check ebookNo existent, false if ebookNo not exist
        if(isValidEbook(_ebookNo) == false) {
            return (false);  // may use revert()
        }
        else { 
            // if previous EbookNo exist, change it next pointer to the deleted ebook next pointer
            if(strCompare(mapBooks[_ebookNo].prev, "") != 0) {  
                mapBooks[mapBooks[_ebookNo].prev].next = mapBooks[_ebookNo].next;
            }
            
            // if next EbookNo exist, change it prev pointer to the deleted ebook prev pointer
            if(strCompare(mapBooks[_ebookNo].next, "") != 0) {  
                mapBooks[mapBooks[_ebookNo].next].prev = mapBooks[_ebookNo].prev;
            }
            
            // If the deleted EbookNo it is the first ebook in list, update the second ebook as the new first ebook
            if(strCompare(tempFirstEbookNo, _ebookNo) == 0 && strCompare(mapBooks[_ebookNo].next, "") != 0) {
                tempFirstEbookNo = mapBooks[_ebookNo].next;
            }
            
            // If the deleted EbookNo it is the last ebook in list, update the second last ebook as the new last ebook
            if(strCompare(tempLatestEbookNo, _ebookNo) == 0 && strCompare(mapBooks[_ebookNo].prev, "") != 0) {
                tempLatestEbookNo = mapBooks[_ebookNo].prev;
            }
            
            // If only one ebook exist, deleted ebook will cause First & Latest pointers to Empty
            if(totalEbook == 1) {  
                tempFirstEbookNo = "";
                tempLatestEbookNo = "";
            }
            
            delete mapBooks[_ebookNo];
            totalEbook = sub(totalEbook, 1);  // deduct ebook counter
            
            return (true);
        }
    }

   
}