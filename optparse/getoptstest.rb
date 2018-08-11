require 'optparse'
# : を付けると引数を取る
params = ARGV.getopts('abc:d:AB:C', 'alpha', 'brabo:', 'charlie:', 'delta:delta').inject({}) { |hash,(k,v)| hash[k.to_sym] = v; hash }
p params



