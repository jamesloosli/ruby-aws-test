#!/usr/bin/ruby

require 'aws-sdk'
require_relative 'config/aws'

require 'optparse'
require 'optparse/time'
require 'yaml'
require 'uuid'
require 'pp'

def parse_options
  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [options] [values]"
    opts.on('-f FILE','--file FILE','Specify the file to upload <required>') do |f|
      options[:file] = f
    end
    opts.on('-v','--verbose','Run verbosely') do |v|
      options[:verbose] = v
    end
    opts.on_tail('-h','--help','Display this screen') do
      puts opts
      exit
    end
  end

  begin
    optparse.parse!
    mandatory = [:file]
    missing = mandatory.select{ |param| options[param].nil? }
    if not missing.empty?
      puts "Missing options: #{missing.join(', ')}"
      puts optparse
      exit
    end
  rescue OptionParser::InvalidOption, OptionParser::MissingArgument
    puts $!.to_s
    puts optparse
    exit
  end

  if options[:verbose]
    puts "Options:"
    puts options.to_s
  end
  return options
end

if __FILE__ == $0
  #Do work.
  begin
    options = parse_options
  
    puts "Starting connection" if options[:verbose]
    s3 = AWS::S3.new
    uuid = UUID.new
    
    puts "Checking for available bucket" if options[:verbose]
    if s3.buckets.count == 0
      puts "Creating bucket" if options[:verbose]
      bucket_name = "#{uuid.generate}"
      bucket = s3.buckets.create(bucket_name)
      if bucket.exists?
        puts "Bucket #{bucket.name}} created" if options[:verbose]
      else 
        raise "Couldn't create bucket"
      end
    else
      arr = s3.buckets.collect(&:name)
      #Just use the first bucket.
      bucket = s3.buckets[arr[0]]
      if bucket.exists? 
        puts "Using existing bucket with id #{arr[0]}" if options[:verbose]
      else
        raise "Couldn't use the bucket I found. Doesn't Exist. You should never see this message. Abandon ship."
      end
    end
    
    puts "Opening file for upload" if options[:verbose]
    file = File.open(options[:file],'rb') or raise "Couldn't open file."

    puts "Uploading file" if options[:verbose]
    obj_key = "#{uuid.generate}"
    obj = bucket.objects[obj_key]
    obj.write(file) or raise "Couldn't write to object"
    #return link 

    puts "Generating link, valid for 24h" if options[:verbose]
    link = obj.url_for(:read, :expires => 86400) or raise "Couldn't create link"

    puts "Link to file: #{link}" 

  rescue Exception => msg
    puts msg
  end
end
