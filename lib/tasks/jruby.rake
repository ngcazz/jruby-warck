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
Created-By: jruby.rake/PT Inovação
MANIFEST

BUILD_DIR = "tmp/war"
WEB_INF   = BUILD_DIR + "/WEB-INF"
META_INF  = BUILD_DIR + "/META-INF"

namespace :jruby do 
  desc "Create a .war package out of this application"
  task :package => :compile do
    raise "!! Couldn't find a suitable web.xml file" unless File.exists? "config/web.xml"

    Rake::Task["assets:precompile"].invoke if Rake::Task["assets:precompile"]
    
    mkdir_p BUILD_DIR
    mkdir_p "#{BUILD_DIR}/assets" if Rake::Task["assets:precompile"]
    mkdir_p WEB_INF
    mkdir_p META_INF

    puts "++ Adding MANIFEST to #{META_INF}"
    manifest = File.new(META_INF + "/MANIFEST.MF", "w")
    manifest.puts(MANIFEST_MF)
    manifest.close
    
    puts "++ Adding web.xml to #{WEB_INF}"
    cp "config/web.xml", "#{WEB_INF}"

    puts "++ Moving .class files to #{WEB_INF}"
    @class_files.each do |file|
      mkdir_p file.pathmap(WEB_INF + "/%d") unless File.exists? file.pathmap(WEB_INF + "/%d")
      mv file, (WEB_INF + "/" + file)
    end

    puts "++ Copying public files to #{BUILD_DIR}"

    public_files = FileList["public/**/*"].exclude(/^public\/assets$/)

    public_files.each do |file|
      cp file, file.pathmap("%{public,#{BUILD_DIR}}d/%f")
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
    web_xml.puts(ERB.new(WEB_XML).result(binding))
    web_xml.close

    puts "++ config/web.xml created"
  end

  desc "Compiles all the Ruby sources to class files"
  task :compile do    
    @ruby_files  = FileList["**/*.rb"]
    
    jrc_output  = `jrubyc #{@ruby_files.join(" ")}`
    
    @class_files = FileList["**/*.class"] - FileList["tmp/**/*.class"]

    unless @ruby_files.size.eql?(@class_files.size)
      puts "** Warning: it seems that some ruby files were not compiled" 
      puts ".rb files: #{@ruby_files.size}"
      puts ".class files: #{@class_files.size}"
    end
  end

  desc "Clears current build artifacts (web.xml and tmp/war)"
  task :clean do
    Rake::Task["jruby:clean:webxml"].invoke
    Rake::Task["jruby:clean:builddir"].invoke
  end

  namespace :clean do
    task :webxml do
      rm "config/web.xml" rescue puts "config/web.xml not found, skipping..."
    end

    task :builddir do
      rm_f BUILD_DIR rescue puts "#{BUILD_DIR} not found, skipping..."
    end
  end
end