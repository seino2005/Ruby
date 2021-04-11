#!/usr/local/bin/ruby -Ku
# -*- encoding: utf-8 -*-

# ruby scriptを作成する準備をする


require 'optparse'
require 'kconv'
require 'fileutils'

# コマンドの説明
$desc = ""
# デバッグ文出力フラグ
$debug = false
# コマンド名
$cmdName = File.basename(__FILE__, ".*")

###########################################################################
# 関数定義
###########################################################################
def debugPrint(str)
  if ($debug == false) then
    return
  end
  print "DEBUG:"
  p Kconv::kconv(str, Kconv::SJIS, Kconv::UTF8)
end

def messagePrint(str)
  if (/\A\s*\z/ =~ str)
    return
  end
  puts Kconv::kconv(str, Kconv::SJIS, Kconv::UTF8)
end

def setup_ruby(arg)
  Dir.chdir( File.dirname(__FILE__) )

  if File.exist?(arg)
    messagePrint("#{arg} is already exist.")
    return
  end

  FileUtils.mkpath(arg)
  new_name = sprintf("%s/%s.rb", arg, arg)
  FileUtils.cp('FILE_u', new_name)

  messagePrint("created #{new_name}")

end

####################################################################################
# option
####################################################################################
opts = OptionParser.new
opts.version = "0.1"
opts.separator "Specific options:"
opts.banner = "Usage: #{$cmdName} [options]\n\t#{$desc}\n"
opts.on_tail("-h", "--help", "Show this message") do
  messagePrint opts.to_s
  exit(0)
end
#opts.on('-c NUM',"get number") {|n| puts "#{n}" }
opts.on_tail("-debug", "debug mode") { $debug = true }

begin
  bufArray = opts.parse(ARGV)
rescue OptionParser::ParseError => e
  puts e
  messagePrint opts.to_s
end

####################################################################################
# main
####################################################################################
bufArray.each { |arg|
  setup_ruby(arg)
}
