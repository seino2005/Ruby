#!/usr/local/bin/ruby -Ku
# -*- encoding: utf-8 -*-

require 'optparse'
require 'kconv'
require 'time'
require 'csv'
require 'pp'

# コマンドの説明
$desc = "csvからdygraphのhtmlを生成する"
# デバッグ文出力フラグ
$debug = false
# コマンド名
$cmdName = File.basename(__FILE__, ".*")

# csvファイルを列分割して別ファイルにする。その上で個別にグラフ化。
$g_split = false

# csvを複数指定して、同じ列を同じグラフにする。
$g_compare = true

###########################################################################
# String extension
# HereDocのindent対応
###########################################################################
class String
    def undent
        min_space_num = self.split("\n").delete_if{|s| s=~ /^\s*$/ }.map{|s| s[/^\s*/].length }.min
        self.gsub(/^[ \t]{,#{min_space_num}}/, '')
    end
end

###########################################################################
# クラス定義
###########################################################################
class CreateHtml
  attr_accessor :csvFiles
  def initialize()
    @csvFiles = Array.new
    @htmlFileData = ""
  end
  
  def createFile()
    self.createHtmlStr()
    
    # ファイル名を日付から生成
    filename = Time.now.strftime("%Y%m%d%H%M%S") + '.html'
    File.open(filename, 'w') { |file|
      file.puts(@htmlFileData)
    }
    messagePrint("create #{filename}")
  end
  
  # 複数のcsvファイルで、同じ列を同じグラフに出す。
  # つまり、APIごとのcsvを作る。
  def createMergeCsvFiles()
    fileNames = Array.new
    
    # key:API name, value:データ配列の配列（csv数分）
    bufHash = Hash.new
    @csvFiles.each {|file|
      # csv data:配列の配列
      csvDatas = readCSV(file)
      # 1列目からキーワード(API name)取得
      apiNames = csvDatas[0]
      # 行ごとのデータを列に変換
      newCsvDatas = csvDatas.transpose()
      
      if (bufHash.size == 0)
        # keywordごとにデータ格納
        apiNames.each_with_index {|keyword, idx|
          bufHash[keyword] = [ newCsvDatas[idx] ]
        }
      else
        # keywordごとにデータ格納
        bufHash.each {|keyword,val|
          # keyがあるか
          idx = apiNames.find_index(keyword)
          if (idx != nil)
            bufHash[keyword].push( newCsvDatas[idx] )
          end
        }
      end
      
    }
    
    # keyごとにcsvを生成する
    bufHash.each {|keyword, values|
      strBufArray = Array.new
      # values:配列の配列
      values.each_with_index {|csvData, csvIndex|
        csvData.each_with_index {|elem, index|
          if (csvIndex == 0)
            if (index == 0)
              strBufArray[index] = sprintf("number,%d_%s", csvIndex+1, elem)
            else
              strBufArray[index] = sprintf("%d,%s", index, elem)
            end
          else
            if (index == 0)
              strBufArray[index] += sprintf(",%d_%s", csvIndex+1, elem)
            else
              strBufArray[index] += sprintf(",%s", elem)
            end
          end
        }
      }
      
      strBuf = strBufArray.join("\n")
      
      # ファイル名を日付から生成
      filename = Time.now.strftime("%Y%m%d%H%M%S")
      filename = sprintf("%s_%s.csv", filename, keyword)
      filename = filename.gsub(/:+/,'_')
      File.open(filename, 'w') { |file|
        file.puts(strBuf)
      }
      fileNames.push(filename)
    }
    
    @csvFiles = fileNames
  end
  
  def splitCsvFiles()
    bufArray = Array.new
    @csvFiles.each {|elem|
      bufArray += self.splitCsvFileByColumn(elem)
    }
    @csvFiles = bufArray
  end
  
  # csvファイルを列分割する。ファイル生成し、ファイル名を戻す。
  # その際に1列目として番号を入れる。
  def splitCsvFileByColumn(file)
    lists = Array.new
    
    # csv data:配列の配列
    csvDatas = readCSV(file)
    
    # 行ごとのデータを列に変換
    newCsvDatas = csvDatas.transpose()
    newCsvDatas.each {|elem|
      # elemは配列で、csv１つ分のデータとなる
      filename = File.basename(file, ".*") + '_' + elem[0] + '.csv'
      filename = filename.gsub(/:+/,'_')
      lists.push(filename)
      File.open(filename, 'w') { |file|
        number = 0
        elem.each {|line|
          if (number == 0)
            str = sprintf("number,%s\n", line)
          else
            str = sprintf("%d,%s\n", number, line)
          end
          file.puts(str)
          number += 1
        }
      }
    }
    
    return lists
  end
  
  def createHtmlStr()
    # csvファイルごとにグラフのコードを生成
    csvGraphs = ""
    graphId = 1
    @csvFiles.each {|elem|
      csvName = File.basename(elem)
      graphCode = %Q[
      <h1>#{csvName}</h1>
      <div id="graphdiv_#{graphId}"></div>
      <script type="text/javascript">
      var container = document.getElementById("graphdiv_#{graphId}");
      g = new Dygraph(container,  "#{csvName}",
                      {
                         rollPeriod: 14,
                         showRoller: true,
                         ylabel: 'Exectime (S)',
                         xlabel: 'Number of executions',
                         width: 640,
                         height: 480,
                         digitsAfterDecimal: 4
                      });
      </script>
      ]
      csvGraphs += graphCode
      graphId += 1
      
    }
    
    # heredoc
    @htmlFileData = <<-HTML.undent
    <!DOCTYPE html>
    <html>
    <head>
    <script type="text/javascript" src="dygraph-combined.js"></script>
    </head>
    <body>
    #{csvGraphs}
    </body>
    </html>
    HTML
    
    
  end
end

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

# CSVを読み込み、配列の配列として戻す
def readCSV(filename)
  resultArray = Array.new

  # CSVファイルの読み込み
  File.open(filename) { |file|
    while line = file.gets
      row = CSV.parse_line( Kconv::kconv(line, Kconv::UTF8, Kconv::SJIS) )
      resultArray.push( row )
    end
  }

  return resultArray
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
opts.on_tail("-s", "split mode") { $g_split = true }
opts.on_tail("-c", "compare mode") { $g_compare = true }

begin
  bufArray = opts.parse(ARGV)
  if ($g_split && $g_compare)
    messagePrint("[ERROR]:Can not specify both -s and -c.")
    exit(1)
  end

rescue OptionParser::ParseError => e
  puts e
  messagePrint opts.to_s
end

####################################################################################
# main
####################################################################################

$g_createHtml = CreateHtml.new
$g_createHtml.csvFiles = bufArray
if $g_split
  # split
  # csvファイルを列でsplitして、列ごとのグラフ
  $g_createHtml.splitCsvFiles()
elsif $g_compare
  # compare
  # 複数のcsvファイルで、同じ列を同じグラフに出す。
  # つまり、APIごとのcsvを作る。
  $g_createHtml.createMergeCsvFiles()
end
$g_createHtml.createFile()

