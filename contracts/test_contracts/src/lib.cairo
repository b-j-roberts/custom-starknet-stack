use starknet::SyscallResult;

extern fn bash_command_syscall(
    command: ByteArray,
) -> SyscallResult<felt252> implicits(GasBuiltin, System) nopanic;

#[starknet::interface]
trait IHelloStarknet<TContractState> {
    fn increase_balance(ref self: TContractState, amount: felt252);
    fn get_balance(self: @TContractState) -> felt252;
}

#[starknet::contract]
mod HelloStarknet {
    #[storage]
    struct Storage {
        balance: felt252, 
    }

    #[abi(embed_v0)]
    impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
        fn increase_balance(ref self: ContractState, amount: felt252) {
            assert!(amount != 0, "Amount cannot be 0");
            let command: ByteArray = "pwd";
            let res = super::bash_command_syscall(command).unwrap();
            println!("res increase: {}", res);
            let res = super::bash_command_syscall("./scripts/test.sh");
            if res.is_err() {
                println!("script error: {}", res.unwrap_err().len());
                return;
            }
            let value = res.unwrap();
            println!("script res: {}", value);
            self.balance.write(self.balance.read() + amount + value);
        }

        fn get_balance(self: @ContractState) -> felt252 {
            let command: ByteArray = "echo 'this is a test of using a lot of text.... hello world'";
            let res = super::bash_command_syscall(command).unwrap();
            println!("res get: {}", res);
            self.balance.read()
        }
    }
}
