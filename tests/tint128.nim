import nuclear


var nucl: Nuclear[hint128]

block store:
  nucl.store ~[5,0]
  echo repr cast[hint128](nucl)
block load:
  assert nucl.load == ~[5,0]
  # Compiler error?

echo "Done"
