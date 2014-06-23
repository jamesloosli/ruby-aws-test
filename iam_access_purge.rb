#!/usr/bin/ruby

require 'aws-sdk'
require_relative 'config/aws'

require 'optparse'
require 'yaml'
require 'pp'

def parse_options
  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: #{__FILE__} [options] [values]"
    opts.on('-u USER','--username USER','Specify the username <required>') do |u|
      options[:user] = u
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
    mandatory = [:user]
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

def purge_all_credentials(o, u, v) 
  #get all credentials
  user = o.users[u]
  keys = user.access_keys
  keys.each do |k|
    puts "Deleting Key with ID #{k.id.to_s}" if v
    k.delete
  end
end

if __FILE__ == $0
  #Do work.
  options = parse_options

  ##Init iam object
  puts "Starting connection" if options[:verbose]
  iam = AWS::IAM.new
  puts "Purging credentials" if options[:verbose]
  purge_all_credentials(iam, options[:user], options[:verbose])
end
