#!/usr/bin/env ruby
# Merges private Velja rules into a plist file.
# Usage: ruby merge_rules.rb <plist_path> <private_rules_json_path>
require 'json'

plist_path = ARGV[0]
private_json_path = ARGV[1]

private_rules = JSON.parse(File.read(private_json_path))
exit 0 if private_rules.empty?

# Extract current rules from plist as JSON
current_rules_json = `plutil -extract rules json -o - '#{plist_path}' 2>/dev/null`
current_rules = current_rules_json.strip.empty? ? [] : JSON.parse(current_rules_json)

# Merge, deduplicating by rule id
existing_ids = current_rules.map { |r| JSON.parse(r)["id"] rescue nil }.compact
private_rules.each do |rule_json|
  rule = JSON.parse(rule_json)
  current_rules << rule_json unless existing_ids.include?(rule["id"])
end

# Write merged rules back into the plist
merged_json = JSON.generate(current_rules)
system("plutil -replace rules -json '#{merged_json}' '#{plist_path}'")
