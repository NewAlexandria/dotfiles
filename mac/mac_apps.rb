
require 'open3'

class MacApps
  attr_accessor :raw, :apps, :my_apps

  def initialize(input=nil)
    @raw  = sys_profile_apps
    @apps = format_raw
  end

  def user_apps
    apps.reject do |a|
      a['location'].scan(/\/System/).any? ||
        a['location'].scan(/\/Library/).any?
    end
  end

  def user_app_name
    user_apps.collect{|a| a['name'] }.sort
  end

  def brew_apps
    apps.select {|a| a['location'].scan(/Cellar/).any? }
  end

  private

  def sys_profile_apps
    raw = Open3.popen3('system_profiler  SPApplicationsDataType') do |i, o, e, t|
      o.read
    end
  end

  def format_raw
    raw
      .split("Applications:\n\n",2)[1]
      .split(/:?\n\n/,)
      .each_slice(2).to_a.map { |el|
        h={}
        h['raw']=el.last&.strip&.split(/\n\s*/)
        h['name']=el.first.strip
        h['e'] = h['raw'].map { |el|
          e=el.split(":",2)
          {e.first.downcase => e.last}
        }.each { |elh|
          h.merge(elh) }; h
        }.map { |ap|
          e=ap['e'].dup
          ap.delete('e')
          ap.delete('raw')
          ap.merge(e.reduce(&:merge))
        }
  end
end
