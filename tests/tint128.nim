import nuclear


var nucl: Nuclear[hint128]

block store:
  nucl.store ~[5,0]
block load:
  assert nucl.load == ~[5,0]
block exchange:
  assert nucl.exchange(~[7,0]) == ~[5,0]
block compareExchange:
  var expected = ~[7,0]
  assert nucl.compareExchange(expected, ~[5,0]) == true
  assert nucl.load == ~[5,0]
block fetchAdd:
  assert nucl.fetchAdd(~[3,0]) == ~[5,0]
  assert nucl.load == ~[8,0]
block fetchSub:
  assert nucl.fetchSub(~[3,0]) == ~[8,0]
  assert nucl.load == ~[5,0]
block fetchAnd:
  assert nucl.fetchAnd(~[3,0]) == ~[5,0]
  assert nucl.load == ~[1,0]
block fetchOr:
  assert nucl.fetchOr(~[6,0]) == ~[1,0]
  assert nucl.load == ~[7,0]
block fetchXor:
  assert nucl.fetchXor(~[5,0]) == ~[7,0]
  assert nucl.load == ~[2,0]



echo "Done"
