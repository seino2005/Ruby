# csv data list, search by tags

require 'optparse'
require 'kconv'
require 'pp'
require 'csv'

# コマンドの説明
$desc = ''
# デバッグ文出力フラグ
$debug = false
# コマンド名
$cmdName = File.basename(__FILE__, '.*')

class Database
  def initialize
    # csv data, key:name, values: tags
    @db = {}
    # list of tag
    @tags = []
  end

  def parse(filename)
    # CSVファイルの読み込み
    File.open(filename) do |file|
      while line = file.gets
        row = CSV.parse_line(Kconv.kconv(line, Kconv::UTF8, Kconv::SJIS))
  
        key_str = row.shift
        if @db.key?(key_str)
          messagePrint("[Error] duplicate key #{key_str}")
        else
          @db[key_str] = row.select{|e| e != nil }.map{ |e| e.strip }
          @tags |= @db[key_str]
        end
      end
    end

  end

  def search(keys)
    result = []
    keys.each{ |elem|
      result |= @db.find_all { |k,v| v.find { |tag| tag == elem } }
    }

    result.map { |e| e[0] }
  end

  def dump
    pp @db
    pp @tags
  end

end

$database = Database.new


###########################################################################
# 関数定義
###########################################################################
def debugPrint(str)
  return if $debug == false

  print 'DEBUG:'
  p Kconv.kconv(str, Kconv::SJIS, Kconv::UTF8)
end

def messagePrint(str)
  if /\A\s*\z/ =~ str
    return
  end

  puts Kconv.kconv(str, Kconv::SJIS, Kconv::UTF8)
end


####################################################################################
# option
####################################################################################
opts = OptionParser.new
opts.version = '0.1'
opts.separator 'Specific options:'
opts.banner = "Usage: #{$cmdName} [options]\n\t#{$desc}\n"
opts.on_tail('-h', '--help', 'Show this message') do
  messagePrint opts.to_s
  exit(0)
end
# opts.on('-c NUM',"get number") {|n| puts "#{n}" }
opts.on_tail('-debug', 'debug mode') { $debug = true }

begin
  bufArray = opts.parse(ARGV)
rescue OptionParser::ParseError => e
  puts e
  messagePrint opts.to_s
end

####################################################################################
# main
####################################################################################
bufArray.each do |filename|
  $database.parse(filename)
end

loop do
  printf("tag_search$ ")
  input = $stdin.gets.chomp

  exit(0) if input[0] == "q"

  case input
  when "quit","q" then
    exit(0)
  when "dump" then
    $database.dump
  else
    res = $database.search(input.split(","))
    res.each { |e| puts e }
#    messagePrint("illegal command:#{input}")
  end


end