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
    constructor(address[] memory _owners, uint _minimum){
        owners = _owners;
        mininimum = _minimum;
    }

    // events
    event balanceAdded(uint amount, address indexed deliveredTo);
    event TransferRequestCreated(uint _txid, uint _amount, address _initiator, address _receiver);
    event transferedAmounts(uint amount, address indexed sentFrom, address deliveredTo);



    // anyone should be able to deposit ether into the contract
    function deposit() public payable returns (uint) {
        emit balanceAdded(msg.value, msg.sender);
        return address(this).balance;
    }

    // creating a pending transaction with false sent status and 0 aprovals having
    function createTnx(address recipient, uint amount) public onlyOwners returns(Transfer[] memory) {
        address[] memory emptyArray;
        transfersScope.push( Transfer(payable(msg.sender), payable(recipient), amount, false, emptyArray ) );
        emit TransferRequestCreated( (transfersScope.length - 1), amount, msg.sender, recipient);
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
                emit transferedAmounts(transfersScope[_index].amount, msg.sender, transfersScope[_index].recipient);
            }
        }
    }

    // transfer anywhere with 2/3 approval
    function transfer(address recipient, uint amount) private onlyOwners returns(bool){

        // checking for conditions
        require(msg.sender != recipient, "You can't send money to yourself.");

        uint previousSenderBalance = address(this).balance;
        payable (recipient).transfer(amount);

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