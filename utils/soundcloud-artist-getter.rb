
raws = # list of sets URLs

# get sets
res = raws.split("\n").map{|s| Open3.capture3("yt-dlp #{s}") }

# extract set info from download results
sets = res
  .flatten
  .select{|g|g.is_a?(String)}
  .reject(&:empty?)
  .map{|g|g.split("\n")}
  .compact
  .map{|g|
    g.map{|l|
      l.is_a?(String) \
      && ((
        l.match(/Downloading playlist: (.*)/) \
        || l.match(/Downloading item ([0-9]+) of [0-9]+/) \
        || l.match(/Destination: (.*)/) \
        || l.match(/\] (.*) has already been downloaded/)
      )||[])[1] \
      || nil
    }.compact
  }

# move songs to dirs
sets
  .map{|s|
    album=s[0];
    s[1..-1]
      .each_slice(2)
      .map{|nn|
        f="#{nn[0].rjust(2,'0')} - #{nn[1]}";
        `mkdir -p "#{album}"` ;
        `mv -f "#{nn[1]}" "#{album}/#{f}"`
      }
  }

songs = # list of songs URLS, without sets

# quick list of song names
snms = sets.flatten.sort.reverse.map(&:downcase);

# remove songs names that are in sets
# not working
news = songs.reject{|s|
  snms.any?{|n| n.include? s.split('/').last.downcase }
}

# download songs
news.map{|s| Open3.capture3("yt-dlp #{s}") }

# rerun the code for # move songs to dirs
