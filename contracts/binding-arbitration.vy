# Binding Arbitration

# params
arbiter: public(address)
arbiterFee: public(uint256)
arbiterFeeIsPercent: public(bool)

firstParty: public(address)
secondParty: public(address)
winner: public(address)

startTime: public(uint256)
# when endTime exists it is when the abitration was resolved or canceled
endTime: public(uint256)
# true when the abitration was ended by cancellation else the arbitration was resolved or is still open
canceled: public(bool)

# Keep track of $$$
escrow: public(HashMap[address, uint256])

@external
def __init__(_arbiter: address, _arbiterFee: uint256, _arbiterFeeIsPercent: bool):
    """
    Start a binding arbitration with the provided arbiter and their fee
    """
    # using underscores in param names because examples did
    self.arbiter = _arbiter
    self.arbiterFee = _arbiterFee
    self.arbiterFeeIsPercent = _arbiterFeeIsPercent
    self.startTime = block.timestamp

# Enter binding arbitration with the arbiter
@external
@payable
def enter():
    """
    Allow a party to enter the binding arbitration for this arbiter and hold their Ether in escrow.
    If there are already two parties or if this party is the arbiter or one of the parties
    """
    # check if there is a spot available and that all addresses are different
    assert self.firstParty == ZERO_ADDRESS or self.secondParty == ZERO_ADDRESS
    assert msg.sender != self.arbiter
    assert msg.sender != self.firstParty
    assert msg.sender != self.secondParty
    if self.firstParty == ZERO_ADDRESS:
        self.firstParty = msg.sender
    elif self.secondParty == ZERO_ADDRESS:
        self.secondParty = msg.sender

    self.escrow[msg.sender] += msg.value

@external
def withdraw():
    """
    When one party has entered but not the other, the one party can withdraw their funds and exit the abitration with no fee.
    When two parties have entered and the arbiter hasn't done anything, neither party can withdraw their funds.
    When two parties have entered and the arbiter cancels, both parties can withdraw their funds with no fee.
    When two parties have entered and the arbiter decides a winner, the winner can withdraw all the funds minus the arbiter fee and the arbiter can withdraw the arbiter fee
    """
    pass

@external
def cancel():
    """
    The arbiter can cancel the arbitration after two parties have entered it
    """
    assert msg.sender == self.arbiter
    assert self.winner == ZERO_ADDRESS
    assert self.firstParty != ZERO_ADDRESS and self.secondParty != ZERO_ADDRESS
    assert not self.canceled

    self.canceled = True
    self.endTime = block.timestamp

@external
def decide(_winner: address):
    """
    The arbiter decides who has won this binding arbitration
    """
    assert msg.sender == self.arbiter
    assert self.winner == ZERO_ADDRESS
    assert self.firstParty != ZERO_ADDRESS and self.secondParty != ZERO_ADDRESS
    assert not self.canceled

    self.winner = _winner
    self.endTime = block.timestamp