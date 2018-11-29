# Geniuslyrics
A Ruby script that automatically fetches lyrics based on artist, album or song name

# Dependencies
    gem install poltergeist
    gem install zaru
    
# How to install
First, install Ruby if it hasn't been installed:
    sudo apt-get install ruby
    
Then, fetch the geniuslyrics script and make it executable:
    git clone https://github.com/dominiquemb/geniuslyrics.git
    cd geniuslyrics
    sudo chmod +x geniuslyrics.rb
   
# How to use
    ./geniuslyrics.rb [OPTIONS]
    
# Available options

Search by song name
-s [song name with spaces] or --song [song name with spaces]
    ./geniuslyrics.rb --song infinite without fulfillment
    
Search by album name
-a [album name with spaces] or --album [album name with spaces]
    ./geniuslyrics.rb --album visions
    
Search by artist name
-A [artist name with spaces] or --artist [artist name with spaces]
    ./geniuslyrics.rb --artist grimes
    
Include debugging messages + lyrics in console output
-v or --verbose
     ./geniuslyrics.rb --artist grimes -v
    
Real-world example:
     ./geniuslyrics.rb -A grimes -a visions -s infinite without fulfillment --verbose
    
# Where do the lyrics get saved?
The lyrics get saved inside a directory named after the artist. The examples above will create a new directory called Grimes containing album and song subdirectories. The lyrics are saved in a text file.
