# -*- encoding: utf-8 -*-
desc "Create a .war package out of this application"
task :package => :compile do
  Rake::Task["assets:precompile"].invoke if Rake::Task["assets:precompile"]
  create_archive_dirs
  add_manifest_file
  add_deployment_descriptor
  add_rackup_file if File.exists?(RACKUP_FILE)
  add_class_files
  add_public_files
  add_additional_files
  archive_war
end

desc "Compiles all the Ruby sources to class files"
task :compile do    
  @ruby_files  = FileList["**/*.rb"]
  
  `jrubyc #{@ruby_files.join(" ")}`
  
  @class_files = FileList["**/*.class"] - FileList["tmp/**/*"]

  unless @ruby_files.size.eql?(@class_files.size)
    puts "** Warning: it seems that some ruby files were not compiled" 
    puts ".rb files: #{@ruby_files.size}"
    puts ".class files: #{@class_files.size}"
  end
end

desc "Generate a custom webxml for this application"
task :webxml, :framework do |t, args|
  args.with_defaults(:framework => :rack)

  context_listener = {
    :rack  => "org.jruby.rack.RackServletContextListener",
    :rails => "org.jruby.rack.rails.RailsServletContextListener"
  }[args[:framework]]

  raise "!! config/web.xml already exists" if File.exists?("config/web.xml")

  web_xml = File.new("config/web.xml", "w")
  web_xml.puts(ERB.new(File.exists?("config/web.xml.erb") ? File.read("config/web.xml.erb") : WEB_XML).result(binding))
  web_xml.close

  puts "++ config/web.xml created#{if File.exists?("config/web.xml.erb") then " from config/web.xml.erb" end}"
end

desc "Clears current build artifacts (web.xml and tmp/war)"
task :clean => ["clean:builddir", "clean:war"]

namespace :clean do
  task :webxml do
    rm "config/web.xml" rescue puts "config/web.xml not found, skipping..."
  end

  task :builddir do
    rm_f BUILD_DIR rescue puts "#{BUILD_DIR} not found, skipping..."
    mkdir_p BUILD_DIR
  end

  task :war do
    rm Dir.pwd.pathmap("#{RUNNING_FROM}/%f.war") rescue puts Dir.pwd.pathmap("#{RUNNING_FROM}/%f.war") + " not found, skipping..."
  end
end
