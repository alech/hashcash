require 'rake'
require 'rake/testtask'

desc "Install the hashcash package (non-gem)"
task :install do
    dest = File.join(Config::CONFIG['sitelibdir'], 'hashcash')
    Dir.mkdir(dest) unless File.exists? dest
    cp 'lib/hashcash.rb', dest, :verbose => true
end

desc 'Install the hashcash package as a gem'
task :install_gem do
    ruby 'hashcash.gemspec'
    file = Dir["*.gem"].first
    sh "gem install #{file}"
end

Rake::TestTask.new do |t|
    t.libs << 'lib'
    t.warning = true
    t.test_files = FileList['test/test_*']
end
