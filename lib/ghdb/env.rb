# frozen_string_literal: true

module Ghdb
  # Environment variable helper with fallback support
  # Priority: AWS_* > GHDB_* > TIGRIS_STORAGE_* > TIGRIS_*
  #
  # AWS standard variables (used by Fly.io):
  #   AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, BUCKET_NAME, AWS_ENDPOINT_URL_S3
  module Env
    module_function

    def access_key_id
      ENV['AWS_ACCESS_KEY_ID'] ||
        ENV['GHDB_ACCESS_KEY_ID'] ||
        ENV['TIGRIS_STORAGE_ACCESS_KEY_ID'] ||
        ENV['TIGRIS_ACCESS_KEY_ID']
    end

    def secret_access_key
      ENV['AWS_SECRET_ACCESS_KEY'] ||
        ENV['GHDB_SECRET_ACCESS_KEY'] ||
        ENV['TIGRIS_STORAGE_SECRET_ACCESS_KEY'] ||
        ENV['TIGRIS_SECRET_ACCESS_KEY']
    end

    def bucket
      ENV['BUCKET_NAME'] ||
        ENV['GHDB_BUCKET'] ||
        ENV['TIGRIS_STORAGE_BUCKET'] ||
        ENV['TIGRIS_BUCKET']
    end

    def endpoint
      ENV['AWS_ENDPOINT_URL_S3'] ||
        ENV['GHDB_ENDPOINT'] ||
        ENV['TIGRIS_STORAGE_ENDPOINT'] ||
        ENV['TIGRIS_ENDPOINT'] ||
        'fly.storage.tigris.dev'
    end

    def replica_url
      return nil unless bucket && !bucket.empty?

      "s3://#{bucket}?endpoint=#{endpoint}&region=auto"
    end

    def write_litestream_config(db_path, path: '')
      config = <<~YAML
        dbs:
          - path: #{db_path}
            replicas:
              - type: s3
                bucket: #{bucket}
                path: #{path}
                endpoint: #{endpoint}
                region: #{ENV['AWS_REGION'] || 'auto'}
                access-key-id: #{access_key_id}
                secret-access-key: #{secret_access_key}
      YAML

      tmp = "/tmp/ghdb-litestream-#{Process.pid}.yml"
      File.write(tmp, config)
      tmp
    end

    def credentials_env
      {
        'AWS_ACCESS_KEY_ID' => access_key_id,
        'AWS_SECRET_ACCESS_KEY' => secret_access_key,
        'AWS_ENDPOINT_URL_S3' => endpoint,
        'AWS_REGION' => ENV['AWS_REGION'] || 'auto'
      }
    end

    def valid?
      access_key_id && secret_access_key && bucket
    end

    def missing_vars
      missing = []
      unless access_key_id
        missing << 'access_key_id (AWS_ACCESS_KEY_ID, GHDB_ACCESS_KEY_ID, or TIGRIS_STORAGE_ACCESS_KEY_ID)'
      end
      unless secret_access_key
        missing << 'secret_access_key (AWS_SECRET_ACCESS_KEY, GHDB_SECRET_ACCESS_KEY, or TIGRIS_STORAGE_SECRET_ACCESS_KEY)'
      end
      missing << 'bucket (BUCKET_NAME, GHDB_BUCKET, or TIGRIS_STORAGE_BUCKET)' unless bucket
      missing
    end
  end
end
