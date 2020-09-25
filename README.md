# Kneel before the Arbiter!

An Ethereum smart contract to do binding arbitration. Two addresses send Ether and the address of the arbiter. The arbiter address sends one of the two addresses to decide who won. The winner can withdraw the combined Ether initially supplied. If only one address has started binding arbitration they can withdraw their Ether and cancel binding arbitration. The arbiter can send a NULL address (or hit a different function) to cancel arbitration after it has been entered and the other addresses can withdraw the Ether they originally sent.
