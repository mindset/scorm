module Scorm::Command
  class Extract < Base
    def index
      package = args.shift.strip rescue ''
      raise(CommandFailed, "Invalid package.") if package == ''

      Scorm::Package.open(package) do |pkg|
        display "Extracted package to #{pkg.path}"
      end
    end
  end
end