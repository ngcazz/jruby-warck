# -*- encoding: utf-8 -*-

require 'zip/zip'
require 'erb'

WEB_XML = <<-XML
<!DOCTYPE web-app PUBLIC
  "-//Sun Microsystems, Inc.//DTD Web Application 2.3//EN"
  "http://java.sun.com/dtd/web-app_2_3.dtd">
<web-app>
  <filter>
    <filter-name>RackFilter</filter-name>
    <filter-class>org.jruby.rack.RackFilter</filter-class>
  </filter>
  <filter-mapping>
    <filter-name>RackFilter</filter-name>
    <url-pattern>/*</url-pattern>
  </filter-mapping>

  <listener>
    <listener-class><%= context_listener %></listener-class>
  </listener>
</web-app>
XML

MANIFEST_MF = <<-MANIFEST
Manifest-Version: 1.0
Created-By: jruby.rake
MANIFEST

RUNNING_FROM = Dir.pwd

BUILD_DIR = "tmp/war"
WEB_INF   = BUILD_DIR + "/WEB-INF"
META_INF  = BUILD_DIR + "/META-INF"

RACKUP_FILE = "config.ru"

# additional filename patterns to be included inside the archive
# default is all yml files
SELECT_FILES = FileList[IO.readlines("select.files").map(&:chomp).reject { |line| line[0] == "#" }] rescue FileList["**/*.yml", "**/*.erb"]
# filename patterns to be rejected from the archive
# default is none
REJECT_FILES = FileList[IO.readlines("reject.files").map(&:chomp).reject { |line| line[0] == "#" }] rescue FileList[]

namespace :jruby do 
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
  task :clean do
    %w{ builddir war }.each { |task| Rake::Task["jruby:clean:#{task}"].invoke }
  end

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
end

def create_archive_dirs
  puts "++ Creating archive directories"    
  mkdir_p "#{BUILD_DIR}/assets" if Rake::Task["assets:precompile"]
  mkdir_p WEB_INF
  mkdir_p META_INF
end

def add_manifest_file
  puts "++ Adding MANIFEST to #{META_INF}"
  manifest = File.new(META_INF + "/MANIFEST.MF", "w")
  manifest.puts(MANIFEST_MF)
  manifest.close
end

def add_deployment_descriptor
  puts "++ Adding web.xml to #{WEB_INF}"
  cp "config/web.xml", "#{WEB_INF}"
end

def add_rackup_file
  puts "++ Copying #{RACKUP_FILE} to #{WEB_INF}"
  cp RACKUP_FILE, WEB_INF
end

def add_class_files
  puts "++ Moving .class files to #{WEB_INF}"
  puts "++ Generating .rb stubs in #{WEB_INF}"
  @class_files.each do |file|
    mkdir_p file.pathmap(WEB_INF + "/%d") unless File.exists? file.pathmap(WEB_INF + "/%d")
    mv file, (WEB_INF + "/" + file)

    stub = File.open((WEB_INF + "/" + file).sub(/\.class$/, ".rb"), "w")
    stub.puts("load __FILE__.sub(/\.rb$/, '.class')")
    stub.close  
  end
end

def add_public_files
  puts "++ Copying public files to #{BUILD_DIR}"
  
  (FileList["public/**/*"] - FileList[REJECT_FILES]).each do |file|
    if File.directory?(file)
      mkdir_p file.pathmap("%{public,#{BUILD_DIR}}d/%f")
    else
      cp file, file.pathmap("%{public,#{BUILD_DIR}}d/%f")
    end
  end
end

def add_additional_files
  puts "++ Copying additional files to #{WEB_INF}"
  FileList[SELECT_FILES].each do |file|
    mkdir_p file.pathmap("#{WEB_INF}/%d") unless File.exists?(file.pathmap("#{WEB_INF}/%d"))
    cp file, file.pathmap("#{WEB_INF}/%d/%f")
  end
end 

def archive_war
  puts "++ Creating war file #{Dir.pwd.pathmap("%f")}.war"
  Zip::ZipFile.open(Dir.pwd.pathmap("#{RUNNING_FROM}/%f.war"), Zip::ZipFile::CREATE) do |zip|
    Dir.chdir(BUILD_DIR)
    Dir["**/"].each { |d| zip.mkdir(d, 0444) }
    FileList["**/*"].exclude { |f| File.directory?(f) }.each { |f| zip.add(f, f) }

    zip.close
  end
end
