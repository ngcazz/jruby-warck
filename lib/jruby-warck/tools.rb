module JrubyWarck::Tools
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
end
