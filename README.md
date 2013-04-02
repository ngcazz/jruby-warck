jruby-warck
===========

Kinda like warbler, except WAR-only and contained in a single Rakefile.

It's still missing quite a few features, but you can already use it to boot the default Rails app.

Available tasks:
  * jruby:package
    Creates WAR file structure inside tmp/war.
    Places all .class files, assets etc., in their corresponding directories of the WAR structure.
  * jruby:webxml
    Dumps a configurable web.xml inside the config/ subdirectory.
  * jruby:compile
    Compiles each *.rb in the current directory tree.
  * jruby:clean
    Deletes generated files (config/web.xml, tmp/war).