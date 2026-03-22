#!/usr/bin/env ruby
# Strips private rules from an exported Velja plist before committing to the public repo.
# Usage: ruby strip_private_rules.rb <plist_path> <private_rules_json_path>
require 'json'

plist_path = ARGV[0]
private_json_path = ARGV[1]

private_rules = JSON.parse(File.read(private_json_path))
private_ids = private_rules.map { |r| JSON.parse(r)["id"] rescue nil }.compact
exit 0 if private_ids.empty?

current_rules_json = `plutil -extract rules json -o - '#{plist_path}' 2>/dev/null`
current_rules = current_rules_json.strip.empty? ? [] : JSON.parse(current_rules_json)

filtered = current_rules.reject { |r| private_ids.include?(JSON.parse(r)["id"]) rescue false }

system("plutil -replace rules -json '#{JSON.generate(filtered)}' '#{plist_path}'")
