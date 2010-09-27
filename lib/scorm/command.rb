require 'scorm/commands/base'

Dir["#{File.dirname(__FILE__)}/commands/*.rb"].each { |c| require c }

module Scorm
  module Command
    class InvalidCommand < RuntimeError; end
    class CommandFailed  < RuntimeError; end

    class << self
      
      def error(msg)
        STDERR.puts(msg)
        exit 1
      end

      def run(command, args)
        begin
          run_internal(command, args.dup)
        rescue Zip::ZipError => e
          error e.message
        rescue InvalidPackage => e
          error e.message
        rescue InvalidManifest => e
          error e.message
        rescue InvalidCommand
          error "Unknown command. Run 'scorm help' for usage information."
        rescue CommandFailed => e
          error e.message
        rescue Interrupt => e
          error "\n[canceled]"
        end
      end

      def run_internal(command, args)
        klass, method = parse(command)
        runner = klass.new(args)
        raise InvalidCommand unless runner.respond_to?(method)
        runner.send(method)
      end

      def parse(command)
        parts = command.split(':')
        case parts.size
          when 1
            begin
              return eval("Scorm::Command::#{command.capitalize}"), :index
            rescue NameError, NoMethodError
              raise InvalidCommand
            end
          when 2
            begin
              return Scorm::Command.const_get(parts[0].capitalize), parts[1]
            rescue NameError
              raise InvalidCommand
            end
          else
            raise InvalidCommand
        end
      end
    end
  end
end