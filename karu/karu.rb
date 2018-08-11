require 'optparse'
require 'json'
require 'pp'

# {
#   "branch":"N1000Dv",
#   "config":"Release",
#   "changelist":"latest",
#   "repo": ["", ""]
# }
# 

$defaultRepo = "//www.example.co.jp/drive"

params = ARGV.getopts('', 'branch:N1000Dv', 'config:Release', 'changelist:latest', "repo:#{$defaultRepo}").inject({}) { |hash,(k,v)| hash[k.to_sym] = v; hash }

pp params


File.open("karu_config.json") do |file|
  retval = JSON.load(file).inject({}) { |hash,(k,v)| hash[k.to_sym] = v; hash }
  pp retval
end


