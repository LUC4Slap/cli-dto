# frozen_string_literal: true
require 'faraday'
require 'json'

class YouTubers
  BASE_URL = 'https://www.googleapis.com/youtube/v3'

  def initialize(perfil_id = nil, color = 'green', video_id = nil, key = nil)
    @perfil_id = perfil_id
    @video_id = video_id
    @key = key
  end

  def retornar_videos
    raise CliError, 'perfil_id (channel_id) é obrigatório' unless @perfil_id

    response = conn.get('search', {
      part: 'snippet',
      channelId: @perfil_id,
      type: 'video',
      maxResults: 50,
      key: @key
    })

    parse_videos(response)
  end

  def retornar_comentarios(video_id = nil)
    vid = video_id || @video_id
    raise CliError, 'video_id é obrigatório' unless vid

    all_items = paginate('commentThreads', {
      part: 'snippet,replies',
      videoId: vid,
      maxResults: 100,
      key: @key
    })

    all_items.flat_map do |thread|
      comment = thread['snippet']['topLevelComment']
      [build_comment(comment['snippet'], comment['id'])] +
        thread.fetch('replies', {}).fetch('comments', []).map { |r| build_comment(r['snippet'], r['id']) }
    end
  end

  def responder_comentario(comment_text, parent_comment_id = nil)
    raise CliError,'video_id é obrigatório para responder' unless @video_id

    if parent_comment_id.nil?
      comments = retornar_comentarios
      raise CliError, 'Nenhum comentário encontrado para responder' if comments.empty?
      parent_comment_id = comments.first[:raw_id]
    end

    payload = {
      snippet: {
        videoId: @video_id,
        parentId: parent_comment_id,
        textOriginal: comment_text
      }
    }

    response = conn.post(
      'comments?part=snippet&key=' + @key,
      payload.to_json,
      { 'Content-Type' => 'application/json' }
    )

    result = JSON.parse(response.body)
    puts "✅ Resposta publicada: #{result.dig('snippet', 'textDisplay')}"
    result.send(@color)
  rescue Faraday::Error => e
    raise "Erro ao responder comentário: #{e.message}"
  end

  private

  def conn
    @conn ||= Faraday.new(url: BASE_URL) do |f|
      f.response :raise_error
      f.adapter Faraday.default_adapter
    end
  end

  def parse_videos(response)
    data = JSON.parse(response.body)
    data['items'].map do |item|
      {
        title: item.dig('snippet', 'title'),
        video_id: item.dig('id', 'videoId'),
        published_at: item.dig('snippet', 'publishedAt'),
        description: item.dig('snippet', 'description')
      }
    end
  end

  def paginate(path, params)
    all_items = []
    page_token = nil

    loop do
      args = params.dup
      args[:pageToken] = page_token if page_token
      result = JSON.parse(conn.get(path, args).body)

      items = result['items'] || []
      all_items.concat(items)

      page_token = result['nextPageToken']
      break unless page_token
    end

    all_items
  end

  def build_comment(snippet, raw_id = nil)
    {
      author: snippet['authorDisplayName'],
      text: snippet['textDisplay'],
      raw_id: raw_id,
      like_count: snippet['likeCount'],
      published_at: snippet['publishedAt']
    }
  end
end
