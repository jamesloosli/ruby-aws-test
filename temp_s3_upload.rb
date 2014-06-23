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

def create_new_bucket(s3)
  u = UUID.new
  bucket_name = "#{u.generate}"
  bucket = s3.buckets.create(bucket_name)
  return bucket
end

def upload_file_to_bucket(file,bucket)
  u = UUID.new
  obj_key = "#{u.generate}"
  obj = bucket.objects[obj_key]
  obj.write(file)
  return obj_key
end

def gen_link_to_file(key,bucket,time)
  obj = bucket.objects[key]
  link = obj.url_for(:read, :expires => time)
  return link
end

if __FILE__ == $0
  options = parse_options

  puts "Starting connection" if options[:verbose]
  s3 = AWS::S3.new
  
  puts "Creating bucket" if options[:verbose]
  bucket = create_new_bucket(s3)

  puts "Opening file for upload" if options[:verbose]
  file = File.open(options[:file],'rb') 

  puts "Uploading file" if options[:verbose]
  new_obj_key = upload_file_to_bucket(file,bucket)

  puts "Generating link, valid for 24h" if options[:verbose]
  link = gen_link_to_file(new_obj_key,bucket,86400)

  puts "Link to file: #{link}" 
end
