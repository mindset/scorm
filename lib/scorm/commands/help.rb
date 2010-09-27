module Scorm::Command
  class Help < Base
    class HelpGroup < Array
      attr_reader :title

      def initialize(title)
        @title = title
      end

      def command(name, description)
        self << [name, description]
      end

      def space
        self << ['', '']
      end
    end

    def self.groups
      @groups ||= []
    end

    def self.group(title, &block)
      groups << begin
        group = HelpGroup.new(title)
        yield group
        group
      end
    end

    def self.create_default_groups!
      group 'Commands' do |group|
        group.command 'help',                         'show this usage'
        group.command 'version',                      'show the gem version'
        group.space
        group.command 'create <name>',                'create a new package skeleton'
        group.command 'bundle [<path to directory>]', 'creates a package from the current directory'
        group.command 'check <path to zip file>',     'runs a test suite against your package'
        group.command 'extract <path to zip file>',   'extracts and checks the specified package'
      end
    end

    def index
      display usage
    end

    def usage
      longest_command_length = self.class.groups.map do |group|
        group.map { |g| g.first.length }
      end.flatten.max

      self.class.groups.inject(StringIO.new) do |output, group|
        output.puts "=== %s" % group.title
        output.puts

        group.each do |command, description|
          if command.empty?
            output.puts
          else
            output.puts "%-*s # %s" % [longest_command_length, command, description]
          end
        end

        output.puts
        output
      end.string + <<-EOTXT
=== Example

 scorm create mypackage
 cd mypackage
 scorm check
 scorm bundle
 scorm extract mypackage.zip

EOTXT
    end
  end
end

Scorm::Command::Help.create_default_groups!