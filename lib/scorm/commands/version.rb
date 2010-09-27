module Scorm::Command
  class Version < Base
    def index
      display Scorm::VERSION
    end
  end
end