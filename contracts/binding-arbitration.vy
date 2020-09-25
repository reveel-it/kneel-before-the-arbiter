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
    assert not _arbiterFeeIsPercent or (_arbiterFee >= 0 and _arbiterFee <= 1)
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
    if self.canceled:
      # the arbiter has cancelled, parties may withdraw
      assert msg.sender == self.firstParty or msg.sender == self.secondParty
    elif self.winner != ZERO_ADDRESS:
      # a winner has been selected, arbiter and winner may withdraw
      assert msg.sender == self.winner or msg.sender == self.arbiter
    elif self.secondParty == ZERO_ADDRESS:
      # Only one party has entered, they may withdraw
      assert msg.sender == self.firstParty
      self.firstParty = ZERO_ADDRESS
    else:
      # This means the arbitration still pending, nobody may withdraw
      assert False
    
    pending_amount: uint256 = self.escrow[msg.sender]
    self.escrow[msg.sender] = 0
    send(msg.sender, pending_amount)

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

    total_winnings: uint256 = self.escrow[self.firstParty] + self.escrow[self.secondParty]

    if self.arbiterFeeIsPercent:
        self.escrow[self.arbiter] = total_winnings * self.arbiterFee
    else:
        self.escrow[self.arbiter] = min(total_winnings, self.arbiterFee)

    self.escrow[self.winner] = total_winnings - self.escrow[self.arbiter]
    self.escrow[self.firstParty] = 0
    self.escrow[self.secondParty] = 0

    self.endTime = block.timestamp