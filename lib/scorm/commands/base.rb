require 'fileutils'

module Scorm::Command
  class Base
    attr_accessor :args
    attr_reader :autodetected_package
    
    def initialize(args)
      @args = args
      @autodetected_package = false
    end
    
    def display(msg, newline=true)
      if newline
        puts(msg)
      else
        print(msg)
        STDOUT.flush
      end
    end

    def error(msg)
      STDERR.puts(msg)
      exit 1
    end

    def extract_package(force=true)
      package = extract_option('--package', false)
      raise(CommandFailed, "You must specify a package name after --package") if package == false
      unless package
        raise(CommandFailed, "No package specified.\nRun this command from package folder or set it adding --package <package name>") if force
        @autodetected_package = true
      end
      package
    end

    def extract_option(options, default=true)
      values = options.is_a?(Array) ? options : [options]
      return unless opt_index = args.select { |a| values.include? a }.first
      opt_position = args.index(opt_index) + 1
      if args.size > opt_position && opt_value = args[opt_position]
        if opt_value.include?('--')
          opt_value = nil
        else
          args.delete_at(opt_position)
        end
      end
      opt_value ||= default
      args.delete(opt_index)
      block_given? ? yield(opt_value) : opt_value
    end
  end
end