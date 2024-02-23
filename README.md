# Custom Starknet Stack

This repo contains git submodules referencing forks of the repos used for Starknet and Cairo development. 

Each forked repo changes its dependencies to use path related dependencies, which link to other forked repos inside `custom-starknet-stack`. This enables easy and fast local development of different parts of the stack, without needing to worry about versioning different repos and setting up a development environment.
