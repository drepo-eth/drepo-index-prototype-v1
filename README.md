# dRepo Index Prototype

This is a prototype implementation of an index registry for a decentralized software repository.

The index is a smart contract that holds a tree structure representing software package releases.
Anyone can create a group. It is represented as an ERC721 token. The owner of this token can create new packages and releases within the group.
Each software release contains an array of string `content`. This content is supposed to reference the locations of artifacts belonging to the given release.
The index contract does not impose an restrictions or formats on the content. Thus, clients must filter invalid formats.
The community running the given repository must create standards and choose to enforce them on-chain. However, this can cause compatibility issues in the future, as the contract code is supposed to be immutable.

Read more about the repository at [drepo.eth](https://drepo.eth) or [drepo.dev](https://drepo.dev)

## Development

The project makes use of [foundry](https://github.com/foundry-rs). The Build is not modified, so standards apply.

```sh
forge install
forge compile
forge test -vv
```
