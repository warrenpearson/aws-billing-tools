#!/usr/bin/env ruby

require 'csv'
require 'json'
require 'optparse'

# Given an instance id and an AWS billing csv file,
# aggregate all associated costs for the month to date,
# including attached volumes
class BoxCoster
  def aggregate_costs(input_file, instance_id, verbose, no_costs)
    total = 0.00

    instance = get_instance(instance_id)
    resources = [instance['id']]
    resources.concat(instance['volumes'])

    if no_costs
      puts resources.inspect
      return
    end

    puts "Getting costs for #{instance['name']}"
    resources.each do |resource|
      resource_total = get_total_for_resource(resource, input_file, verbose)
      total += resource_total
    end

    puts "Total monthly cost: $#{total.round(2)}" if resources.length > 1
  end

  def get_instance(instance_id)
    instance = nil
    instance_json = './instance_info.json'
    instance_info = JSON.parse(File.read(instance_json))
    instance_info.each do |i|
      if i['id'] == instance_id
        instance = i
        break
      end
    end
    instance
  end

  def get_total_for_resource(resource, input_file, verbose)
    rows = `grep #{resource} #{input_file}`.split("\n")
    total = 0.00

    sub_buckets = Hash.new { 0 }

    rows.each do |r|
      CSV.parse(r) do |row|
        amt = row[-3].to_f
        bucket = row[9]
        sub_buckets[bucket] += amt
        total += amt
        log_verbosely(row) if verbose
      end
    end

    sub_buckets.keys.each do |k|
      if sub_buckets[k] > 1
        puts "Monthly cost for #{resource} / #{k}: $#{sub_buckets[k].round(2)}"
      end
    end

    puts "Monthly cost for #{resource}: $#{total.round(2)}"
    total.round(2)
  end

  def log_verbosely(row)
    output = "#{row[5]} #{row[9]} #{row[10]} #{row[13]} #{row[14]} #{row[15]}:"
    output += "#{row[-3]}"
    puts output
  end
end

input_file = ARGV[0]
instance   = ARGV[1]
verbose    = false
no_costs   = false

unless instance && input_file
  puts "Usage: #{__FILE__} <csv_file_name> <instance_id>"
  exit
end

optparse = OptionParser.new do|opts|
  opts.on('-n', '--no-costs', 'Ignore cost details') do
    no_costs = true
  end
  opts.on('-v', '--verbose', 'Show cost details') do
    verbose = true
  end
end

optparse.parse!

BoxCoster.new.aggregate_costs(input_file, instance, verbose, no_costs)
