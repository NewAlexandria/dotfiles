## bucket gateways
#
# https://docs.aws.amazon.com/apigateway/latest/developerguide/integrating-api-with-aws-services-s3.html
# https://auth0.com/blog/securing-aws-http-apis-with-jwt-authorizers/
#

files = Dir.
  children('.').
  select { |f| File.file?(f) } 

file_groups = files.sort.
  map{|f| (f.match(reg) || [])[0] }.
  reject(&:empty?).
  group_by{|ff| ff }.
  map{|g| [g[0].strip, g[1].size ] }.
  reject{|gg| gg[1] == 1 }

mkdirs = file_groups.
  map{|g| Dir.mkdir( File.join(Dir.pwd, g[0])) }


## folders

ff = Dir.glob("**/*/")
ffm = ff.map {|e| [e, e.gsub(' ', '-')] }

## S3 folders

# remove folder/object paths with "./" in them.
# These are accidental unix dot reference uploads
def dot_dirs_for( target_bucket )
  require 'open3'
  puts "⏱  this can take some time, based on the size of the bucket."

	stdout_str, stderr_str, status = Open3.capture3(
		"aws s3 ls --recursive #{target_bucket}"
	)
	sall = stdout_str.split("\n")
	dotdirss = sall.
    map    { |l| l.split(/ [0-9]{1,8} /).map(&:strip) }.
    select { |l| l.last.match(/.*\.\/.*/) }
end

def batch_dot_dirs_rm( target_bucket, dotdirs, slicing=300, threads=@threads )
  threads = [] if !@threads.map(&:alive?).reduce(&:|) || !@times
  dotdirs.each_slice(slicing) do |arr|
    threads.push(
      Thread.new {
        arr.map do |f|
          stdout_str, stderr_str, status = Open3.capture3(
            "aws s3 rm \"#{target_bucket}#{f.last}\"")
          stdout_str.size 
        end
      }
    )
  end
end

def threads_check(threads=@threads)
  threads.
    map(&:alive?).
    map(&:to_s).
    group_by(&:size).
    map {|e| e.last.size }
end


def log_progress( dotdirs, times=@times, threads=@threads )
  times = [] unless threads
  times.push [dotdirs.size, Time.now]
end

def last_log_delta(offset=0, times=@times )
  offset = 0 if offset > 0
  offset = times.length-2 if offset < ((times.length-2) * -1)
  start=offset-1
  cut=start-1
  (times[cut].first - times[start].first) /
    ((times[start].last.to_i - times[cut].last.to_i) / 60 )
end

def est_complete(times=@times)
  Time.now + ((times.last.first / last_log_delta(0, times)) * 60)
end

