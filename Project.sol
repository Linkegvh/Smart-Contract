// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.24 < 0.9.0;

contract MyContract{
    
    //////////////////// Structure Declaration /////////////////////////
    
    // player structure
    struct Player{
        // address id; // uncomment only for deployment
        uint id; // Comment this during deployment
        uint256 balance;
        bool active;
        uint256 total_payment;
    }
    
    // token structure
    struct Token{
        uint id;
        bool active;
    }
    
    //////////////////// Structure Declaration End /////////////////////////
    
    //////////////////// Variable Declaration /////////////////////////
    // Current 'money' in the game
    uint256 public current_pool = 0;
    
    // Random id in which we can check who is the last person the token allocated to
    uint public random_id = 0;
    
    uint256 public peopleCount = 0;
    mapping (uint => Player) public Players;
    
    uint256 public tokenCount = 0;
    mapping (uint => Token) public Tokens;
    
    //////////////////// Variable Declaration End /////////////////////////
    
    //////////////////// Critical Functions /////////////////////////
    
    // uncomment only for deployment
    // event Registration(string);
    // function addPlayer(address player_address) private {
    //     incrementCount();
    //     Players[peopleCount] = Player(player_address, 1000);
    // }
    
    function addPlayer() public {
        incrementCount();
        Players[peopleCount] = Player(peopleCount, 200, true, 0);
    }
    
    
    function addToken() public{
        incrementToken();
        allocate_Token_to_player(tokenCount, true);
    }
    
    
    function token_transfer (uint token_index) public {
        // randomally generate a number to deduct the amonut of balance from user
        uint random_number = (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, token_index))) % 10) + 1;
        uint total_payment = 10 * random_number;

        transfer_to_another_person(token_index, total_payment, true);
        
        // check if the game is over --> meaning no more active tokens
        if (is_it_game_over() == true){
            // trigger payout event
            split_pool();
        }
    }
    
    function activate_token (uint token_index) public {
        allocate_Token_to_player(token_index, true);
        Tokens[token_index].active = true;
    }
    
    //////////////////// Critical Functions End /////////////////////////
    
    //////////////////// helper Functions /////////////////////////

    
    function incrementCount() internal {
        peopleCount += 1;
    }
    
    
    function incrementToken() internal {
        tokenCount += 1;
    }
    
    function allocate_Token_to_player(uint token_index, bool clash_found) internal {
        while(clash_found){
            clash_found = check_clash(random_id);
            random_id = (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenCount))) % peopleCount) + 1;
        }
        Tokens[token_index] = Token(random_id, true);
    }
    
    function check_clash (uint randomid) internal view returns (bool) {
        for (uint256 i = 0; i <= tokenCount; i++){
            if (Tokens[i].id == randomid){
                return true;
            }
        }
        
        // we do not allow tokens to be passed to deactivated players
        // This code here could potentially cause the browser to enter into a state of script take too long to load
        if (Players[randomid].active == false){
            return true;
        }
        
        return false;
    }
    
    function transfer_to_another_person (uint token_index, uint total_payment, bool clash_found) internal {
        uint256 current_balance = Players[Tokens[token_index].id].balance;
        if (current_balance > total_payment){
            Players[Tokens[token_index].id].total_payment += total_payment; // keep track of how much the player has put into the pool
            Players[Tokens[token_index].id].balance = current_balance - total_payment; // minus off player balance from proof of work
            current_pool += total_payment;
            
            // transfer token to the next player
            random_id = (uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, tokenCount))) % peopleCount) + 1;
            while (clash_found){
                clash_found = check_clash(random_id);
                if (clash_found == true){
                    if (random_id <= peopleCount){
                        random_id = random_id + 1;
                    }else{
                        random_id = 1;
                    }
                }
            }

            Tokens[token_index].id = random_id; // transfer token to the next player
        }else{
            // deactivate token and player
            Players[Tokens[token_index].id].total_payment += Players[Tokens[token_index].id].balance; // keep track of how much the player has put into the pool
            current_pool += Players[Tokens[token_index].id].balance;
            Players[Tokens[token_index].id].balance = 0;
            Players[Tokens[token_index].id].active = false;
            Tokens[token_index].active = false;
        }
    }
    
    function is_it_game_over () public view returns (bool) {
        for (uint256 i = 0; i <= tokenCount; i ++){
            // the game is not over if there are still active tokens
            if (Tokens[i].active == true){
                return false;
            }
        }
        return true;
    }
    
    function living_sum () public view returns (uint256) {
        uint256 sum = 0;
        for (uint i = 0; i <= peopleCount; i++)
        {
            if (!Players[i].active) continue;
            sum += Players[i].total_payment;
        }
        return sum;
    }
    event this_is_not_happening(string);
    uint256 public deserved_amount = 10;
    function split_pool () internal {
        uint256 living_total = living_sum();
        // uint256 deserved_amount = 0;
        // emit this_is_not_happening("This is not happening!");
        if (living_total > 0){
            // emit this_is_not_happening("This is not happening twice!");
            for (uint i = 1; i <= peopleCount; i++){
                // emit this_is_not_happening("This is not happening ttt!");
                if (Players[i].active == true){
                    emit this_is_not_happening("This is not happening ffff!");
                    deserved_amount = current_pool * Players[i].total_payment / living_total;
                    Players[i].balance += deserved_amount;
                }
            }
        }
    }

    // Uncomment only for deployment
    //Register funciton, reqires real eth to join 
    // function Register() external payable{
    //     require(msg.value == 1 ether, "Incorrect amount"); 
    //     emit Registration("Registration success, you have now joined the game!");
    //     addPlayer(msg.sender);
    // }
    // Uncomment only for deployment
    // function check_balance() public view returns(uint256){
    //     return Players[check_player_index()].balance;
    // }
    // function check_player_index()private view returns(uint32){
    //     for(uint32 i=1;i<peopleCount+1;i++){
    //         if (Players[i].id ==msg.sender){
    //             return i;
    //         }
    //     }
    //     return 0;
    // }
    // Uncomment only for deployment
    // function pay_transfer(uint256 amount)public{
    //     uint32 index =check_player_index();
    //     require(Players[index].balance>=amount,"Insufficient funds");
    //     Players[index].balance-=amount;
    //     Players_Records[index].total_payment += amount;
    //     current_pool+=amount;
    // }
    
    //////////////////// helper Functions End /////////////////////////
    
}
