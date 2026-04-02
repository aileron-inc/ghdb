# frozen_string_literal: true

require_relative 'lib/ghdb/version'

Gem::Specification.new do |spec|
  spec.name = 'ghdb'
  spec.version = Ghdb::VERSION
  spec.authors = ['AILERON']
  spec.email = ['masa@aileron.cc']

  spec.summary = 'Sync GitHub repository files into SQLite via ActiveRecord.'
  spec.description = 'ghdb syncs GitHub repository blob entries into a SQLite database, managed by ActiveRecord.'
  spec.homepage = 'https://github.com/aileron-inc/ghdb'
  spec.required_ruby_version = '>= 3.2.0'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activerecord', '~> 8.0'
  spec.add_dependency 'front_matter_parser', '~> 1.0'
  spec.add_dependency 'sqlite3', '~> 2.0'
  spec.add_dependency 'ulid-ruby', '~> 1.0'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
