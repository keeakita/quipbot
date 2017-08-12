# Stores secrets

require 'yaml'

module Quipbot
end

module Quipbot::Secrets
  @@secrets = YAML.load_file('./secrets.yaml')

  def self.secrets
    @@secrets
  end
end

