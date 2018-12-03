#!/usr/bin/ruby 

require 'open-uri'
require 'json'
require 'selenium-webdriver'
require 'capybara/poltergeist'
require 'zaru'

options = Hash.new
currentArg = false

# collect arguments
ARGV.each do |arg|
    if arg.index('--') == 0
        key = arg.split('--')[1]
        currentArg = key
        options[key] = []
    elsif arg.index('-') == 0
        key = arg.split('-')[1]
        currentArg = key
        options[key] = []
    else 
        if currentArg
            options[currentArg] << arg
        end
    end
end

albumname = ""
artistname = ""
songname = ""
searchquery = []
searchquerystring = ""
searchurl = ""
lyricstext = ""
verbose = false

# parse arguments
options.keys.each_with_index do |key, index|
    if key == 'a' || key == 'album' 
        albumname = options[key].join("%20")
    elsif key == 'A' || key == 'artist'
        artistname = options[key].join("%20")
    elsif key == 's' || key == 'song'
        songname = options[key].join("%20")
    elsif key == 'v' || key == 'verbose'
        verbose = true
    end
end

if songname.length > 0 && artistname.length > 0
    searchquery << songname
elsif songname.length > 0
    searchquery << songname
end

if artistname.length > 0
    searchquery << artistname
end 

if albumname.length > 0 && songname.length == 0 
    searchquery << albumname
end

# build search query
if searchquery.length > 0
    searchquerystring = searchquery.join("%20")
    searchurl = "https://genius.com/search?q=%s" % searchquerystring
end

if verbose
    p 'Options enabled:'
    p options

    p 'Query URL:'
    p searchurl
end

Capybara.threadsafe = true
#Capybara.default_max_wait_time = 180
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, {js_errors: false})
end

session = Capybara::Session.new(:poltergeist) do |config|
    config.default_max_wait_time = 180
end
session.visit(searchurl)

if songname.length > 0
# if the song name is supplied
    if session.has_selector?('search-result-section')
        first_song_result = session.all('search-result-section')[1]
        p 'section'
        p first_song_result
        if session.has_selector?('.mini_card-title')

            first_song_result.first('.mini_card-title').trigger('click')
            
            if session.has_selector?('.header_with_cover_art-primary_info-title')
                artist_dirname = (Zaru.sanitize! session.first('.header_with_cover_art-primary_info-primary_artist').text).gsub(/\s{1,}/, "_")
                album_dirname = (Zaru.sanitize! session.first('song-primary-album .metadata_unit-info a').text).gsub(/\s{1,}/, "_")

                if verbose
                    p 'Artist directory name:'
                    p artist_dirname

                    p 'Album directory name:' 
                    p album_dirname 
                end

                Dir.mkdir(artist_dirname) unless File.exists?(artist_dirname)

                if File.exists?(artist_dirname)
                    album_dir_path = "%s/%s" % [artist_dirname, album_dirname]
                    Dir.mkdir(album_dir_path) unless File.exists?(album_dir_path)
                end

                lyricstext = ""

                if session.has_selector?('.lyrics')
                    lyricstext = session.first('.lyrics').text

                    songtitle = session.first('.header_with_cover_art-primary_info-title').text
                    songtitle_with_underscores = (Zaru.sanitize! songtitle).gsub(/\s{1,}/, "_")

                    lyrics_path = "%s/%s.txt" % [album_dir_path, songtitle_with_underscores]

                    lyricsfile = File.open(lyrics_path, "w")
                    lyricsfile.puts(lyricstext) 
                    
                    if verbose
                        p "Lyrics for %s:" % songtitle
                        puts lyricstext
                    end

                    lyricsfile.close
                end
            end
        end
    end
elsif albumname.length > 0
# if the albumname is supplied
    session.first('a[set-class-before-navigate="vertical_album_card--active"]').trigger('click')
    if session.has_selector?('album-tracklist-row a')
        if session.has_selector?('album-tracklist-row a')

            if session.has_selector?('.header_with_cover_art-primary_info-primary_artist')
                artist_dirname = (Zaru.sanitize! session.first('.header_with_cover_art-primary_info-primary_artist').text).gsub(/\s{1,}/, "_")
                album_dirname = (Zaru.sanitize! session.first('.header_with_cover_art-primary_info-title').text).gsub(/\s{1,}/, "_")

                if verbose
                    p 'Artist directory name:'
                    p artist_dirname

                    p 'Album directory name:' 
                    p album_dirname 
                end

                Dir.mkdir(artist_dirname) unless File.exists?(artist_dirname)

                if File.exists?(artist_dirname)
                    album_dir_path = "%s/%s" % [artist_dirname, album_dirname]
                    Dir.mkdir(album_dir_path) unless File.exists?(album_dir_path)
                end

                tracklist = session.all('album-tracklist-row a')
                lyricstext = ""

                if verbose
                    p 'total number of songs:'
                    p tracklist.length
                end

                tracklist.each do |track|
                    url = track['href']
                    session.open_new_window
                    session.switch_to_window(session.windows[-1])
                    session.visit(url)
                    if session.has_selector?('.lyrics')
                        lyricstext = session.first('.lyrics').text

                        if session.has_selector?('.header_with_cover_art-primary_info-title')
                            songtitle = session.first('.header_with_cover_art-primary_info-title').text
                            songtitle_with_underscores = (Zaru.sanitize! songtitle).gsub(/\s{1,}/, "_")

                            lyrics_path = "%s/%s.txt" % [album_dir_path, songtitle_with_underscores]

                            lyricsfile = File.open(lyrics_path, "w")
                            lyricsfile.puts(lyricstext) 
                            
                            if verbose
                                p "Lyrics for %s:" % songtitle
                                puts lyricstext
                            end

                            lyricsfile.close

                            session.windows[-1].close()

                            session.switch_to_window(session.windows[0])
                        end
                    end
                end
            end
        end
    end
elsif artistname.length > 0
# if only the artist name is defined
    if session.has_selector?('mini-artist-card')
        p 'current url'
        p session.current_url
        session.first('mini-artist-card a').trigger('click')

        if session.has_selector?('artist-songs-and-albums .full_width_button svg')
            p 'current url'
            p session.current_url
            session.first('artist-songs-and-albums .full_width_button').trigger('click')

            if session.has_selector?('.modal_window')
                p session.first('.modal_window mini-song-card').text

                previousScrollHeight = session.evaluate_script("document.getElementsByClassName('modal_window')[0].scrollTop")
                newScrollHeight = session.evaluate_script("document.getElementsByClassName('modal_window')[0].scrollTop = document.getElementsByClassName('modal_window')[0].scrollHeight")

                p 'previousscrollheight'
                p previousScrollHeight
                p 'scrollheight'
                p newScrollHeight

                p 'number of song results'
                oldTotalResults = session.all('.modal_window mini-song-card').length
                p oldTotalResults

                while previousScrollHeight != newScrollHeight do
                    previousScrollHeight = newScrollHeight
                    newScrollHeight = session.evaluate_script("document.getElementsByClassName('modal_window')[0].scrollTop = document.getElementsByClassName('modal_window')[0].scrollHeight")

                    secondsWaited = 0;

                    while (session.all('.modal_window mini-song-card').length == oldTotalResults) && (secondsWaited <= 30)
                        # Wait for more results to load. After 1 minute, stop waiting and continue.
                        sleep(5)
                        secondsWaited += 5
                        p 'seconds waited'
                        p secondsWaited
                    end

                    oldTotalResults = session.all('.modal_window mini-song-card').length
                end

                p 'previousscrollheight'
                p previousScrollHeight
                p 'scrollheight'
                p newScrollHeight
                
                p 'number of song results'
                tracklist = session.all('.modal_window mini-song-card a')

                tracklist.each do |track|
                    url = track['href']
                    session.open_new_window
                    session.switch_to_window(session.windows[-1])
                    session.visit(url)
                    if session.has_selector?('.lyrics')
                        lyricstext = session.first('.lyrics').text

                        if session.has_selector?('.header_with_cover_art-primary_info-title')
                            artist_dirname = (Zaru.sanitize! session.first('.header_with_cover_art-primary_info-primary_artist').text).gsub(/\s{1,}/, "_")
                            album_dirname = (Zaru.sanitize! session.first('.header_with_cover_art-primary_info-title').text).gsub(/\s{1,}/, "_")

                            if verbose
                                p 'Artist directory name:'
                                p artist_dirname

                                p 'Album directory name:' 
                                p album_dirname 
                            end

                            Dir.mkdir(artist_dirname) unless File.exists?(artist_dirname)

                            if File.exists?(artist_dirname)
                                album_dir_path = "%s/%s" % [artist_dirname, album_dirname]
                                Dir.mkdir(album_dir_path) unless File.exists?(album_dir_path)
                            end

                            songtitle = session.first('.header_with_cover_art-primary_info-title').text
                            songtitle_with_underscores = (Zaru.sanitize! songtitle).gsub(/\s{1,}/, "_")

                            lyrics_path = "%s/%s.txt" % [album_dir_path, songtitle_with_underscores]

                            lyricsfile = File.open(lyrics_path, "w")
                            lyricsfile.puts(lyricstext) 
                            
                            if verbose
                                p "Lyrics for %s:" % songtitle
                                puts lyricstext
                            end

                            lyricsfile.close

                            session.windows[-1].close()

                            session.switch_to_window(session.windows[0])
                        end
                    end
                end
            end
        end
    end
end

if lyricstext.length == 0
    p 'No results found. Try adjusting your search parameters. If the problem persists, contact the developer at conejoplata@gmail.com'
end
