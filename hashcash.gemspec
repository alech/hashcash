require 'rubygems'

spec = Gem::Specification.new do |gem|
    gem.name        = 'hashcash'
    gem.version     = '0.1'
    gem.author      = 'Alexander Klink'
    gem.email       = 'hashcash@alech.de'
    gem.platform    = Gem::Platform::RUBY
    gem.summary     = 'A library to create hash cash stamps as defined on hashcash.org.'
    gem.description =<<'XEOF'
A library for creating and verifying so-called »hash cash stamps«, i.e.
proof of work as defined on hashcash.org.
XEOF
    gem.test_file   = 'test/test_hashcash.rb'
    gem.has_rdoc    = 'true'
    gem.require_path = 'lib'
    gem.extra_rdoc_files = [ 'README' ]

    gem.files = Dir['lib/hashcash.rb'] + Dir['test/test_hashcash.rb'] 
end
