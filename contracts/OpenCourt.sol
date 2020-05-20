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
*
* OpenLaw.io Rinkeby Beta v0.1
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
}

/*****************
OpenCourt Protocol
*****************/
contract OpenCourt is Context { 
    // internal references
    address public judgeDAO;
    address public judgeToken;
    IToken private judge = IToken(judgeToken);
    address public leethToken;
    IToken private leeth = IToken(leethToken);
    string public emoji = "🌐📜⚔️";
    string public procedures;
    
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
    }
    
    event Complaint(address indexed complainant, address indexed respondent, uint256 indexed number, string complaint);
    event ComplaintUpdated(uint256 indexed number, string complaint);
    event ProceduresUpgraded(string procedures);
    event Response(uint256 indexed number, string response);
    event ResponseUpdated(uint256 indexed number, string response); 
    event Verdict(uint256 indexed number, string verdict);
    
    constructor (address _judgeDAO, address _judgeToken, address _leethToken, string memory _procedures) public {
        judgeDAO = _judgeDAO;
        judgeToken = _judgeToken;
        leethToken = _leethToken;
        procedures = _procedures;
    } 
    
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
        emit Response(number, response);
    }
    
    function updateResponse(uint256 number, string memory updatedResponse) public {
        Dispute storage dis = disp[number];
        require(_msgSender() == dis.respondent);
        dis.response = updatedResponse;
        emit ResponseUpdated(number, updatedResponse);
    }
    
    /**Verdict & MGMT*/
    function issueVerdict(uint256 number, string memory verdict) public {
        require(judge.balanceOf(_msgSender()) >= 1, "judgeToken balance insufficient");
        Dispute storage dis = disp[number];
        dis.verdict = verdict;
        dis.resolved = true;
        leeth.transfer(_msgSender(), 1000000000000000000);
        emit Verdict(number, verdict);
    }
    
    function updateJudgeDAO(address _judgeDAO) public {
        require(_msgSender() == judgeDAO, "Caller not authorized.");
        judgeDAO = _judgeDAO;
    }
    
    function updateJudgeToken(address _judgeToken) public {
        require(_msgSender() == judgeDAO, "Caller not authorized.");
        judgeToken = _judgeToken;
    } 
    
    function updateLeethToken(address _leethToken) public {
        require(_msgSender() == judgeDAO, "Caller not authorized.");
        leethToken = _leethToken;
    }
    
    function upgradeProcedures(string memory _procedures) public {
        require(_msgSender() == judgeDAO, "Caller not authorized.");
        procedures = _procedures;
        emit ProceduresUpgraded(procedures);
    } 
}
