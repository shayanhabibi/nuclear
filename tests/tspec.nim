import nuclear

var nucl: Nuclear[int]

block store:
  nucl.store 5

block load:
  assert nucl.load == 5

block exchange:
  assert nucl.exchange(7'u) == 5

block compareExchange:
  var expected = 7
  assert nucl.compareExchange(expected, 5) == true
  assert nucl.load == 5

block fetchAdd:
  assert nucl.fetchAdd(3) == 5
  assert nucl.load == 8

block fetchSub:
  assert nucl.fetchSub(3) == 8
  assert nucl.load == 5

block fetchAnd:
  assert nucl.fetchAnd(3) == 5
  assert nucl.load == 1

block fetchOr:
  assert nucl.fetchOr(6) == 1
  assert nucl.load == 7

block fetchXor:
  assert nucl.fetchXor(5'u) == 7
  assert nucl.load == 2



echo "done"
