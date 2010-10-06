require 'rubygems'
require 'zip/zip'
require 'fileutils'
require 'open-uri'
require 'scorm/datatypes'
require 'scorm/manifest'

module Scorm
  class InvalidPackage < RuntimeError; end
  class InvalidManifest < InvalidPackage; end
  
  class Package
    attr_accessor :name       # Name of the package.
    attr_accessor :manifest   # An instance of +Scorm::Manifest+.
    attr_accessor :path       # Path to the extracted course.
    attr_accessor :repository # The directory to which the packages is extracted.
    attr_accessor :options    # The options hash supplied when opening the package.
    attr_accessor :package    # The file name of the package file.
    
    DEFAULT_LOAD_OPTIONS = { 
      :strict => false,
      :dry_run => false, 
      :cleanup => true,
      :force_cleanup => false,
      :name => nil,
      :repository => nil
    }
    
    def self.set_default_load_options(options = {})
      DEFAULT_LOAD_OPTIONS.merge!(options)
    end
    
    def self.open(filename, options = {}, &block)
      Package.new(filename, options, &block)
    end
    
    # This method will load a SCORM package and extract its content to the 
    # directory specified by the +:repository+ option. The manifest file will be
    # parsed and made available through the +manifest+ instance variable. This
    # method should be called with an associated block as it yields the opened
    # package and then auto-magically closes it when the block has finished. It
    # will also do any necessary cleanup if an exception occur anywhere in the
    # block. The available options are:
    #
    #   :+strict+:     If +false+ the manifest will be parsed in a nicer way. Default: +true+.
    #   :+dry_run+:    If +true+ nothing will be written to the file system. Default: +false+.
    #   :+cleanup+:    If +false+ no cleanup will take place if an error occur. Default: +true+.
    #   :+name+:       The name to use when extracting the package to the 
    #                  repository. Default: will use the filename of the package 
    #                  (minus the .zip extension).
    #   :+repository+: Path to the course repository. Default: the same directory as the package.
    #
    def initialize(filename, options = {}, &block)
      @options = DEFAULT_LOAD_OPTIONS.merge(options)
      @package = filename.respond_to?(:path) ? filename.path : filename
      
      # Check if package is a directory or a file.
      if File.directory?(@package)
        @name = File.basename(@package)
        @repository = File.dirname(@package)
        @path = File.expand_path(@package)
      else
        i = nil
        begin
          # Decide on a name for the package.
          @name = [(@options[:name] || File.basename(@package, File.extname(@package))), i].flatten.join
      
          # Set the path for the extracted package.
          @repository = @options[:repository] || File.dirname(@package)
          @path = File.expand_path(File.join(@repository, @name))
        
          # First try is nil, subsequent tries sets and increments the value with 
          # one starting at zero.
          i = (i || 0) + 1

        # Make sure the generated path is unique.
        end while File.exists?(@path)
      end
      
      # Extract the package
      extract!
                                                        
      # Detect and read imsmanifest.xml
      if exists?('imsmanifest.xml')
        @manifest = Manifest.new(self, file('imsmanifest.xml'))
      else
        raise InvalidPackage, "#{File.basename(@package)}: no imsmanifest.xml, maybe not SCORM compatible?"
      end
      
      # Yield to the caller.
      yield(self)
      
      # Make sure the package is closed when the caller has finished reading it.
      self.close

    # If an exception occur the package is auto-magically closed and any 
    # residual data deleted in a clean way.
    rescue Exception => e
      self.close
      self.cleanup
      raise e
    end
    
    # Closes the package.
    def close
      @zipfile.close if @zipfile
      
      # Make sure the extracted package is deleted if force_cleanup_on_close
      # is enabled.
      self.cleanup if @options[:force_cleanup_on_close]
    end
    
    # Cleans up by deleting all extracted files. Called when an error occurs.
    def cleanup
      FileUtils.rmtree(@path) if @options[:cleanup] && !@options[:dry_run] && @path && File.exists?(@path) && package?
    end
    
    # Extracts the content of the package to the course repository. This will be
    # done automatically when opening a package so this method will rarely be
    # used. If the +dry_run+ option was set to +true+ when the package was
    # opened nothing will happen. This behavior can be overridden with the
    # +force+ parameter. 
    def extract!(force = false)
      return if @options[:dry_run] && !force
      
      # If opening an already extracted package; do nothing.
      if not package?
        return
      end
      
      # Create the path to the course
      FileUtils.mkdir_p(@path)
      
      Zip::ZipFile::foreach(@package) do |entry|
        entry_path = File.join(@path, entry.name)
        entry_dir = File.dirname(entry_path)
        FileUtils.mkdir_p(entry_dir) unless File.exists?(entry_dir)
        entry.extract(entry_path)
      end
    end
    
    # This will only return +true+ if what was opened was an actual zip file.
    # It returns +false+ if what was opened was a filesystem directory.
    def package?
      return false if File.directory?(@package)
      return true
    end
    
    # Reads a file from the package. If the file is not extracted yet (all files
    # are extracted by default when opening the package) it will be extracted
    # to the file system and its content returned. If the +dry_run+ option was
    # set to +true+ when opening the package the file will <em>not</em> be
    # extracted to the file system, but read directly into memory.
    def file(filename)
      if File.exists?(@path)
        File.read(path_to(filename))
      else
        Zip::ZipFile.foreach(@package) do |entry|
          return entry.get_input_stream {|io| io.read } if entry.name == filename
        end
      end
    end
    
    # Returns +true+ if the specified file (or directory) exists in the package.
    def exists?(filename)
      if File.exists?(@path)
        File.exists?(path_to(filename))
      else
        Zip::ZipFile::foreach(@package) do |entry|
          return true if entry.name == filename
        end
        false
      end
    end
    
    # Computes the absolute path to a file in an extracted package given its
    # relative path. The argument +relative+ can be used to get the path 
    # relative to the course repository.
    #
    # Ex.
    #    <tt>pkg.path => '/var/lms/courses/MyCourse/'</tt>
    #    <tt>pkg.course_repository => '/var/lms/courses/'</tt>
    #    <tt>path_to('images/myimg.jpg') => '/var/lms/courses/MyCourse/images/myimg.jpg'</tt>
    #    <tt>path_to('images/myimg.jpg', true) => 'MyCourse/images/myimg.jpg'</tt>
    #
    def path_to(relative_filename, relative = false)
      if relative
        File.join(@name, relative_filename)
      else
        File.join(@path, relative_filename)
      end
    end
    
    # Returns an array with the paths to all the files in the package.
    def files
      if File.directory?(@package)
        Dir.glob(File.join(File.join(File.expand_path(@package), '**'), '*')).reject {|f|
          File.directory?(f) }.map {|f| f.sub(/^#{File.expand_path(@package)}\/?/, '') }
      else
        entries = []
        Zip::ZipFile::foreach(@package) do |entry|
          entries << entry.name unless entry.name[-1..-1] == '/'
        end
        entries
      end
    end
  end
end