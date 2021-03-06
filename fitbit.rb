require "oauth2"

class Fitbit
  def self.authorization
    Base64.encode64(ENV["FITBIT_CLIENT_ID"] + ":" + ENV["FITBIT_CLIENT_SECRET"]).chomp
  end

  def self.saved_session(filename)
    client = OAuth2::Client.new(
      ENV["FITBIT_CLIENT_ID"],
      ENV["FITBIT_CLIENT_SECRET"],
      site: "https://www.fitbit.com",
      authorize_url: "https://www.fitbit.com/oauth2/authorize",
      token_url: "https://api.fitbit.com/oauth2/token"
    )

    token = nil

    if File.exist?(filename)
      token_hash = JSON.parse(File.read(filename))
      token = OAuth2::AccessToken.from_hash(client, token_hash)
    end

    if token.nil?
      url = client.auth_code.authorize_url(
        scope: "weight",
        expires_in: 2592000,
        redirect_uri: "https://danott.co/weight/callback.html",
      )

      puts "Authenticate with Fitbit."
      puts "1. Copy the URL below, and visit it in your browser.\n\n#{url}\n\n"
      print "2. Enter the code: "
      code = gets.chomp
      token = client.auth_code.get_token(
        code,
        grant_type: "authorization_code",
        redirect_uri: "https://danott.co/weight/callback.html",
        headers: { Authorization: "Basic #{authorization}" }
      )
    elsif token.expired?
      token = token.refresh!(headers: { Authorization: "Basic #{authorization}" })
    end

    File.write(filename, JSON.pretty_generate(token.to_hash))
    token
  end
end
