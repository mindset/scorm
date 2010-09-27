module Scorm::Command
  class Bundle < Base
    def index
      name = args.shift.strip rescue '.'
      unless File.exist?(File.join(File.expand_path(name), 'imsmanifest.xml'))
        raise(CommandFailed, "Invalid package, didn't find any imsmanifest.xml file.")
      end
      
      # TODO: Bundle package...
      
      display "Created new SCORM package \"#{name}.zip\"."
    end
  end
end