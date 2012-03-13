begin
 require 'yard'
  YARD::Rake::YardocTask.new(:doc) do |t|
    t.files   = ['lib/**/*.rb']
    t.options = ['--no-private']
  end
rescue LoadError
  STDERR.puts "Install yard if you want prettier docs"
  require 'rdoc/task'
  require 'wbem/version'
  Rake::RDocTask.new(:doc) do |rdoc|
    rdoc.rdoc_dir = "doc"
    rdoc.title = "wbem #{Wbem::VERSION}"
  end
end
