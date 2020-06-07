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
def dot_dirs_for( target_bucket ) do
  require 'open3'

	stdout_str, stderr_str, status = Open3.capture3(
		"aws s3 ls --recursive #{target_bucket}"
	)
	sall = stdout_str.split("\n")
	dotdirss = sall.
    map    { |l| l.split(/ [0-9]{1,8} /).map(&:strip) }.
    select { |l| l.last.match(/.*\.\/.*/) }
end

threads = []; dotdirs.each_slice(300){|arr|  threads.
➣➣push( Thread.new { arr.map{|f| stdout_str, stderr_str, status = Open3.
➣➣capture3("aws s3 rm \"#{target_bucket}#{f.last}\"") ; stdout_str.size }}) }  ;1

threads.map(&:alive?).map(&:to_s).group_by(&:size).map{|e| e.last.size }


