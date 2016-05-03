#!/usr/local/bin/ruby -Ku
# -*- encoding: utf-8 -*-

require 'optparse'
require 'kconv'
require 'time'
require 'csv'
require 'pp'

# description
$desc = "create dygraph html from csv"
# debug flag
$debug = false
# command name
$cmdName = File.basename(__FILE__, ".*")

# split the csv file by the column.
$g_split = false

# compare multiple csv file and pick up the same column.
# same columns of csv files to same graphs.
$g_compare = false

###########################################################################
# String extension
# indent for HereDoc
###########################################################################
class String
    def undent
        min_space_num = self.split("\n").delete_if{|s| s=~ /^\s*$/ }.map{|s| s[/^\s*/].length }.min
        self.gsub(/^[ \t]{,#{min_space_num}}/, '')
    end
end

###########################################################################
# class definition
###########################################################################
class CreateHtml
  attr_accessor :csvFiles
  def initialize()
    @csvFiles = Array.new
    @htmlFileData = ""
  end
  
  def createFile()
    self.createHtmlStr()
    
    # generate filename by date
    filename = Time.now.strftime("%Y%m%d%H%M%S") + '.html'
    File.open(filename, 'w') { |file|
      file.puts(@htmlFileData)
    }
    messagePrint("create #{filename}")
  end
  
  # create merged csv files for column
  def createMergeCsvFiles()
    fileNames = Array.new
    
    # key:API name, value: array of data array(size = number of csv files)
    bufHash = Hash.new
    @csvFiles.each {|file|
      # csv data: array of array
      csvDatas = readCSV(file)
      # To get the keyword(apiNames) from the first column.
      apiNames = csvDatas[0]
      # convert the data of each row to column
      # Limitaion: The size of the array elements of csvDatas must be the same.
      newCsvDatas = csvDatas.transpose()
      
      if (bufHash.size == 0)
        # set data for keyword
        apiNames.each_with_index {|keyword, idx|
          bufHash[keyword] = [ newCsvDatas[idx] ]
        }
      else
        # set data for keyword
        bufHash.each {|keyword,val|
          # key exist?
          idx = apiNames.find_index(keyword)
          if (idx != nil)
            bufHash[keyword].push( newCsvDatas[idx] )
          end
        }
      end
      
    }
    
    # create csv for key
    bufHash.each {|keyword, values|
      strBufArray = Array.new
      # values:  array of array
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
      
      # generate filename by date
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
  
  # Split the csv file by the column.
  # return : splited csv file names
  # Put the number as the first column.
  def splitCsvFileByColumn(file)
    lists = Array.new
    
    # csv data: array of array
    csvDatas = readCSV(file)
    
    # Convert the data of each row to column
    newCsvDatas = csvDatas.transpose()
    newCsvDatas.each {|elem|
      # elem is array and data of the new csv file
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
    # create the code of graph for csv file
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
    <script type="text/javascript" src="http://dygraphs.com/dygraph-combined.js"></script>
    </head>
    <body>
    #{csvGraphs}
    </body>
    </html>
    HTML
    
    
  end
end

###########################################################################
# function defintion
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

# read csv file, return array of array
def readCSV(filename)
  resultArray = Array.new

  # read csv file
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
  $g_createHtml.splitCsvFiles()
elsif $g_compare
  # compare
  $g_createHtml.createMergeCsvFiles()
end
$g_createHtml.createFile()

