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

doc = Nokogiri.XML(open(input))
favourites_collection = doc.xpath('//ns:track', ns: 'http://xspf.org/ns/0/')

mongo_client = MongoClient.new
db = mongo_client.db('db')
collection = db.collection('collection')
collection.remove

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
file_collection.each do |path|
  print "\r#{i}/#{file_collection_count}"
  TagLib::FileRef.open(path) do |fileref|
    unless fileref.null?
      tag = fileref.tag
      title = tag.title
      creator = tag.artist
      found = collection.find_one(title: title, creator: creator)
      unless found.nil?
        # add path as location in output
        collection.remove(title: title, creator: creator)
      end
    end
  end
  i = i + 1
end
puts