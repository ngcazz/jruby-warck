require 'rake'

module JrubyWarck
  module Constants
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
  end
end
