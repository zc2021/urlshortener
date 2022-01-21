require 'pg'
require 'uri'

class DatabaseHandler
  def initialize(logger)
    @connection = if Sinatra::Base.production?
                    PG.connect(ENV['DATABASE_URL'])
                  else
                    PG.connect(dbname: 'psql-urlshortener')
                  end
    @logger = logger
  end

  def disconnect
    connection.close
  end

  def shrink(url)
    unless valid?(url)
      return { error: 'Invalid URL' }
    end
    begin
      sql = 'INSERT INTO urls (original_url) VALUES ($1);'
      query(sql, url)
      select_sql = 'SELECT short_url FROM urls WHERE original_url=$1;'
      short_url = query(select_sql, url)[0]['short_url'].to_i
    rescue PG::Error => e
      select_sql = 'SELECT short_url FROM urls WHERE original_url=$1;'
      short_url = query(select_sql, url)[0]['short_url'].to_i
    end
    { original_url: url, short_url: short_url }
  end

  def original(num)
    sql = 'SELECT original_url FROM urls WHERE short_url=$1;'
    original_url = query(sql, num)[0]['original_url']
    original_url
  end

  private

  attr_reader :connection, :logger

  def query(statement, *params)
    logger.info "#{statement} | #{params}"
    connection.exec_params(statement, params)
  end

  def valid?(url)
    URI::regexp(['http', 'https']).match?(url)
  end
end