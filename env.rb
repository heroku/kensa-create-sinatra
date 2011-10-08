require 'json'
$manifest = JSON.parse(File.read('addon-manifest.json'))
ENV["HEROKU_USERNAME"] ||= $manifest['id']
ENV["HEROKU_PASSWORD"] ||= $manifest['api']['password']
ENV['SSO_SALT']        ||= $manifest['api']['sso_salt']
ENV["TZ"] = "UTC"
