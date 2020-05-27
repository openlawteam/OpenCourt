/**
** ██████╗ ██████╗ ███████╗███╗   ██╗        
* ██╔═══██╗██╔══██╗██╔════╝████╗  ██║        
* ██║   ██║██████╔╝█████╗  ██╔██╗ ██║        
* ██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║        
* ╚██████╔╝██║     ███████╗██║ ╚████║        
*  ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝        
*                                           
** ██████╗ ██████╗ ██╗   ██╗██████╗ ████████╗
* ██╔════╝██╔═══██╗██║   ██║██╔══██╗╚══██╔══╝
* ██║     ██║   ██║██║   ██║██████╔╝   ██║   
* ██║     ██║   ██║██║   ██║██╔══██╗   ██║   
* ╚██████╗╚██████╔╝╚██████╔╝██║  ██║   ██║   
*/

pragma solidity 0.5.17;
/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IToken { // brief ERC-20 interface
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/*****************
OpenCourt Protocol
*****************/
contract OpenCourt is Context { 
    // internal references
    address public judgeToken = 0x0fd583A2161B08526008559dc9914613679ef68e;
    IToken private judge = IToken(judgeToken);
    address public judgementToken = 0x0776400cE11E99ff18293F65fD4d36EC50d7cd6a;
    IToken private judgement = IToken(judgementToken);
    string public emoji = "🌐📜⚔️";
    string public procedures = "procedures.codeslaw.eth";
    
    // dispute tracking 
    uint256 public dispute; 
    mapping (uint256 => Dispute) public disp;
    
    struct Dispute {  
        address complainant; 
        address respondent;
        uint256 number;
        string complaint;
        string response;
        string verdict;
        bool resolved;
        bool responded;
    }
    
    event Complaint(address indexed complainant, address indexed respondent, uint256 indexed number, string complaint);
    event ComplaintUpdated(uint256 indexed number, string complaint);
    event Response(uint256 indexed number, string response);
    event Verdict(uint256 indexed number, string verdict);
    
    /**************
    COURT FUNCTIONS
    **************/
    /**Complaint*/
    function submitComplaint(address respondent, string memory complaint) public {
	uint256 number = dispute + 1; 
	dispute = dispute + 1;
	    
        disp[number] = Dispute( 
            _msgSender(),
            respondent,
            number,
            complaint,
            "PENDING",
            "PENDING",
            false,
            false);
                
        emit Complaint(_msgSender(), respondent, number, complaint);
    }
    
    function updateComplaint(uint256 number, string memory updatedComplaint) public {
        Dispute storage dis = disp[number];
        require(_msgSender() == dis.complainant);
        dis.complaint = updatedComplaint;
        emit ComplaintUpdated(number, updatedComplaint);
    }
    
    /**Response*/
    function submitResponse(uint256 number, string memory response) public {
	Dispute storage dis = disp[number];
        require(_msgSender() == dis.respondent);
        dis.response = response;
        dis.responded = true;
        emit Response(number, response);
    }

    /**Verdict*/
    function issueVerdict(uint256 number, string memory verdict) public {
        Dispute storage dis = disp[number];
        require(dis.responded == true);
        require(judge.balanceOf(_msgSender()) >= 1, "judgeToken balance insufficient");
        require(_msgSender() != dis.complainant || _msgSender() != dis.respondent);
        dis.verdict = verdict;
        dis.resolved = true;
        judgement.transfer(_msgSender(), 1000000000000000000);
        emit Verdict(number, verdict);
    }
}
