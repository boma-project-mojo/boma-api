pragma solidity ^0.4.18;

contract BomaPresence {
  address public owner = msg.sender;

  mapping (address => bool) party;

  function present(address participant) public {
    require(msg.sender == owner);
    party[participant] = true;
  }

  function isPresent(address participant) public view returns (bool) {
    return party[participant] == true;
  }
}

// https://remix.ethereum.org/#optimize=true&version=soljson-v0.4.24+commit.e67f0147.js