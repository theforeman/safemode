task :default => [:test]

task :test do
  ['test/unit', 'test/test_helper', 'test/test_all'].each do |file|
    require file
  end
end
