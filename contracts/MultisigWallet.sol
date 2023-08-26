// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract MultisigWallet {

    // array of addresses of the owners
    address[] owners;

    // minimal signatures
    uint mininimum;

    // requests for approval
    struct Transfer {
        address payable sender;
        address payable recipient;
        uint amount;
        bool tnxSent;
        address[] ownersAproved;
    }

    // array of transaction needed for aproval check
    Transfer[] transfersScope;

    // mapping( addess => mapping (transactionID => false/true ))
    mapping( address => mapping(uint => bool) ) ownersApprovens;

    //Should only allow people in the owners list to continue the execution.
    modifier onlyOwners(){
        require(exists(msg.sender));
        _;
    }

    // checking if sender is one of the owners
    function exists(address oneOfowners) private view returns (bool) {
        for (uint i = 0; i < owners.length; i++) {
            if (owners[i] == oneOfowners) {
                return true;
            }
        }
        return false;
    }

    // constructor should initialize the owners list and the limit 
    //constructor(address[] memory _owners, uint _mininimum) {
    constructor(){
        address ownerOne = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        address onwerTwo = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        address onwerThree = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
        owners = [ownerOne, onwerTwo, onwerThree];
        mininimum = 2;
    }


    // events
    event balanceAdded(uint amount, address indexed deliveredTo);
    event transferedAmounts(uint amount, address indexed sentFrom, address deliveredTo);



    // anyone should be able to deposit ether into the contract
    function deposit() public payable returns (uint) {
        //balance[msg.sender] += msg.value;
        emit balanceAdded(msg.value, msg.sender);
        return address(this).balance;
    }

    // creating a pending transaction with false sent status and 0 aprovals having
    function createTnx(address recipient, uint amount) public onlyOwners returns(Transfer[] memory) {
        address[] memory emptyArray;
        transfersScope.push( Transfer(payable(msg.sender), payable(recipient), amount, false, emptyArray ) );
        return transfersScope;
    }

    // geting transaction from the scope of pending
    function getTrnx(uint _index) public view onlyOwners returns(address, uint, bool, uint) {
        return (transfersScope[_index].recipient, transfersScope[_index].amount, transfersScope[_index].tnxSent, transfersScope[_index].ownersAproved.length );
    }

    // aproving or not transactions from the scrope of pending
    function approve(uint _index) public onlyOwners {
        
        if( !transfersScope[_index].tnxSent ) {

            if ( transfersScope[_index].ownersAproved.length == 0 ) {

                aprovedSuccess(_index);

            } else {

                // checking if current sender already make a approval for this transaction
                for (uint i = 0; i < transfersScope[_index].ownersAproved.length; i++) {
                    
                    if (transfersScope[_index].ownersAproved[i] == msg.sender) {
                        //return error "You've already approved this transaction";
                        break;
                    } else {
                        aprovedSuccess(_index);
                    }
                }

            }
            
        }

    }

    function aprovedSuccess(uint _index) private onlyOwners {
        transfersScope[_index].ownersAproved.push(msg.sender);
 
        // checking how many aproval now trnx has
        if( transfersScope[_index].ownersAproved.length >= mininimum ) {
            if ( transfer(transfersScope[_index].recipient, transfersScope[_index].amount) ) {
                transfersScope[_index].tnxSent = true;
            }
        }
    }

    // transfer anywhere with 2/3 approval
    function transfer(address recipient, uint amount) private onlyOwners returns(bool){

        // checking for conditions
        require(msg.sender != recipient, "You can't send money to yourself.");

        uint previousSenderBalance = address(this).balance;
        payable (recipient).transfer(amount);

        emit transferedAmounts(amount, msg.sender, recipient);

        if ( (address(this).balance == previousSenderBalance - amount) ) {
            return true;
        } else {
            return false;
        }

    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

}