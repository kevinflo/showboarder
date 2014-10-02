class ActsController < ApplicationController
  def mb
    render :json => MusicBrainz::Artist.search(params[:act].gsub("?term=", ""))
  end

  def esuggest #echonest artist suggest
    artists = Echowrap.artist_suggest(:name => params[:act], results: 5)
    # names = {}
    # artists.each do |a|
    #   names[a.id] = a.name
    # end

    names = []
    artists.each do |a|
      names << {id: a.id, value: a.name}
    end    

    render :json => names
  end

  def eretrieve #echonest artist search with single response
    # artist = Echowrap.artist_search(:name => params[:act], bucket: 'urls').first
    render :json => Act.echo_by_name(params[:act])
  end
end