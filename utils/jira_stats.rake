# Generated from Jira by the Export > XML menu on the search view
# https://adsixty.atlassian.net/sr/jira.issueviews:searchrequest-xml/16908/SearchRequest-16908.xml?tempMax=1000
# filter: "project = BT AND type not in (Task, Sub-task)"

require "nokogiri"

start_date = "2016-01-01"
target_status = "Done"

fields = %w(
  assignee
  key
  updated
  status
)
adjunct = [
]
contractors = [
]

namespace :jira do
  namespace :stats do
    # desc "Print out Story Point stats from ./jira.xml"
    task :by_week do
      j2 = Nokogiri::XML( File.open("jira.xml"))
      h = Hash.from_xml(j2.to_s)

      # Get only the jira cards from the export file
      jj = h["rss"]["channel"]["item"].map {|card|
        a={
          "story_points" => card["customfields"]["customfield"].find {|f|
                              f["customfieldname"]=="Story Points"
                            }.try(:[],"customfieldvalues").try(:[],"customfieldvalue")
        }

        # keep the whitelisted fields
        fields.reduce(a) {|acc,field|
          acc[field] = card[field]
          acc
        }

      # filter by time and status
      }.each{|card|
        card["updated"] = Date.parse(card["updated"])
      }.select{|w| 
        w["updated"] >= Date.parse(start_date) && 
        w["status"] == target_status

      # Group by Week
      }.group_by{|card| 
        card["updated"].cweek 
      }.reduce({}){|acc,(idx,week)| 
        # Remove non-dev team
        acc[idx] = week.reject{|c| 
          adjunct.include?(c["assignee"]) 

        # Group by Person
        }.group_by{|card| 
          card["assignee"] 

        # Sum all of their Story Points in the time period
        }.reduce({}) {|pers,(name,cards)|
          pers.merge({
            name => cards.inject(0) {|sum, hash| sum + hash["story_points"].to_i} 
          })
        }
        acc
      }

      # Weekly total of Story Points for the wholte team
      ja = jj.reduce({}){|acc,(w,users)| acc.merge({
        "Week #{w}" => users.values.inject(:+)
      })}

      # Weekly total of Story Points for each user, sans contractors
      jt = jj.reduce({}){|acc,(w,users)| acc.merge({
        "Week #{w}" => users.reject{|k,v| contractors.include?(k) }.values.inject(:+)
      })}

      # Weekly totals math
      loss = ja.reduce({}){|acc,(w,pts)| acc.merge({
        "Week #{w}" => pts - jt[w] 
      })}

      puts "Story Points, per member"
      jj.each do |w,team|
        puts "Week #{w}"
        puts team.sort.to_h
      end
      puts "Story Points, whole team"
      puts ja
      puts "Story Points, core team only"
      puts jt
      puts "Story Points, without contractors"
      puts loss
    end
  end
end
