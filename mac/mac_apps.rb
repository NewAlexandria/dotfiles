
require 'open3'

class MacApps
  attr_accessor :raw, :apps, :my_apps

  def initialize(input=nil)
    @raw  = sys_profile_apps
    @apps = format_raw
  end

  def user_apps
    apps
      .reject{|a| a['location'].scan(/^\\System/) }
  end

  private

  def sys_profile_apps
    raw = Open3.popen3('system_profiler  SPApplicationsDataType') do |i, o, e, t|
      o.read
    end
  end

  def format_raw
    raw
      .split("Applications:\n\n",2)[1].split(/:\n\n/,)
      .split("\n").map(&:strip)
      .reject(&:empty?)
      .flatten[1..-1]
      .each_slice(7)
      .map {|el| el.map{|i| i.split(":",2) } }
      .map {|el| 
        el
          .tap{|a| a[0] = a.first.reverse; a[0][0]='name' }
          .reduce({}) {|h,(k,v)| h[k.downcase&.strip]=v&.strip; h }
    }
  end
end
