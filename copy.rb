#!/usr/bin/ruby
require 'fileutils'
require 'nokogiri'

if ARGV.count != 2 then
  puts "Wrong number of arguments\n\tcopy.rb xspf-file destination"
  exit
end

src = ARGV[0]
dest = ARGV[1]

doc = Nokogiri.XML(open(src))
collection = doc.xpath('//ns:location', ns: 'http://xspf.org/ns/0/')
collection_size = collection.count
i = 1
collection.each do |location|
  print "\r#{i}/#{collection_size}"
  file_path = location.content
  unless File.new(file_path).exists?
    FileUtils.copy(file_path, dest)
  end
  i = i + 1
end
puts