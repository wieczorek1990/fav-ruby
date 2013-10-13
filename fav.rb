#!/usr/bin/ruby
require 'nokogiri'
require 'find'
require 'taglib'
require 'mongo'
include Mongo

if ARGV.count != 3 then
  puts "Usage:\n\truby fav.rb lastfm-xspf-file output-xspf-file search-directory"
  exit
end

input = ARGV[0]
output = ARGV[1]
dir = ARGV[2]

mongo_client = MongoClient.new
db = mongo_client.db('db')
collection = db.collection('collection')
collection.remove

doc = Nokogiri.XML(open(input))
favourites_collection = doc.xpath('//ns:track', ns: 'http://xspf.org/ns/0/')
favourites_collection.each do |track|
  collection.insert(title: track.children[0].children.text, creator: track.children[1].children.text)
end

file_collection_count = 0
file_collection = []
Find.find(dir) do |path|
  if File.basename(path) =~ /\.(flac|ogg|mp3)$/ then
    file_collection_count = file_collection_count + 1
    file_collection << path
  end
end

i = 1
doc = Nokogiri::XML::Document.new
doc.encoding = 'UTF-8'
playlist_node = Nokogiri::XML::Node.new('playlist', doc)
playlist_node['xmlns'] = 'http://xspf.org/ns/0/'
playlist_node['version'] = 1
track_list_node = Nokogiri::XML::Node.new('trackList', doc)
playlist_node << track_list_node
doc << playlist_node
file_collection.each do |path|
  print "\r#{i}/#{file_collection_count}"
  TagLib::FileRef.open(path) do |fileref|
    unless fileref.null?
      tag = fileref.tag
      title = tag.title
      creator = tag.artist
      found = collection.find_one(title: title, creator: creator)
      unless found.nil?
        track_node = Nokogiri::XML::Node.new('track', doc)
        location_node = Nokogiri::XML::Node.new('location', doc)
        title_node = Nokogiri::XML::Node.new('title', doc)
        location_node << Nokogiri::XML::Text.new(path, doc)
        title_node << Nokogiri::XML::Text.new(title, doc)
        track_node << location_node
        track_node << title_node
        track_list_node << track_node
        collection.remove(title: title, creator: creator)
      end
    end
  end
  i = i + 1
end
File.new(output, 'w').write(doc.to_xml)
puts
