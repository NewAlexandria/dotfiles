#!/usr/bin/ruby

# usage:  path_to_script --dry-run=false 50 --github-org=newalexandria --repos=octavo,klassextant

require 'thread'
require 'thwait'
require 'open3'

dry_run = (
  ARGV
    .select { |i| i.match(/dry-run/) }
    .first || ''
  ).split("=").last  != 'false'

GITHUB_ORG = (
  ARGV
    .select { |i| i.match(/github-org/) }
    .first || ''
  ).split("=").last
exit if GITHUB_ORG.empty?

HOURS_TO_KEEP = ARGV[1].to_i || 50
puts "cut-off at #{HOURS_TO_KEEP} hours"

TARGET_REPOS = (
  ARGV
    .select { |i| i.match(/repos/) }
    .first || ''
  ).split(",")
exit if TARGET_REPOS.empty?
# target_repos = ['api', 'webapp', 'doc-service']

ephemeral_ns = "%s-pr-%s"
ephemeral_ns_rx = Regexp.new(/.*-pr-[0-9]+/)

# deprecated
repo, stat = Open3.capture2 'git config --get remote.origin.url'
repo_name = repo.split('/').last.split('.git').first

# gather github PRs
cmd = "gh pr list -R  '#{GITHUB_ORG}/%s'"
pr_numbers = TARGET_REPOS.reduce([]) do |pr_nums, repo|
  prs_raw, stat = Open3.capture2(cmd % repo)
  prs = prs_raw.split("\n").map{|prl| prl.split("\t") }
  pr_nums.concat prs.map(&:first)
end

# gather all the namespaces
cmd_get_namespaces = "kubectl get namespaces"
cmd_rm_namespaces = "kubectl delete namespace %s"
# cmd_rm_namespaces = "time"

kube_api, stat = Open3.capture2(cmd_get_namespaces)

ns_targets = kube_api
  .split("\n")
  .map(&:split)
  .select{|(ns,active,hours)| ns.match(ephemeral_ns_rx) }

count_hours = -> (hours) {
  hours
    .split(/(?<=[hmd])/)
    .map { |t| t.scan(/([0-9]+)([hmd])/) }
    .flatten(1)
    .reduce(0) { |acc,tt|
      case tt[1];
      when 'm';
        acc += tt[0].to_i/60;
      when 'h';
        acc += tt[0].to_i;
      when 'd';
        acc += tt[0].to_i*24; 
      end;
      acc
    }
  }

# namespace groups
saveable_ns = pr_numbers.map{|pr_number| ephemeral_ns % [repo_name, pr_number] }

killable_ns = ns_targets
  .select {|(ns,active,hours)| count_hours.call(hours) > HOURS_TO_KEEP }
  .map(&:first)
  .reject {|ns| saveable_ns.include?(ns) }

puts "only acting on repos `#{TARGET_REPOS.join(", ")}`"
puts "❌  to kill ❌"
puts killable_ns
puts "🔒  to keep 🔒"
puts ns_targets.map(&:first) - killable_ns

if dry_run 
  puts "➡️  dry run.  noop ⬅️"  
else
  threads = (killable_ns || ['']*4).map do |ns| 
    Thread.new {
      # Thread.current['kube_kill'] = Open3.capture2((cmd_rm_namespaces))
      Thread.current['kube_kill'] = Open3.capture2((cmd_rm_namespaces % ns))
      # Thread.current['kube_kill'] = Open3.capture2((cmd_rm_namespaces))
      # returns kube_rm_output, stat
    }
  end
  ThreadsWait.all_waits(threads) do |t|
    t.join; puts t['kube_kill'].first
  end
  puts "done"
end
