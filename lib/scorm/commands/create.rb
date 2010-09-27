module Scorm::Command
  class Create < Base
    def index
      name = args.shift.strip rescue ''
      raise(CommandFailed, "Invalid package name.") if name == ''

      FileUtils.mkdir_p(name)
      Dir.glob(File.join(File.dirname(File.expand_path(__FILE__)), '../../../skeleton/*')).each do |file|
        FileUtils.cp(file, name)
        display "#{name}/#{File.basename(file)}"
      end
      display "Created new SCORM package \"#{name}\"."
    end
  end
end