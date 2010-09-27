module Scorm
  
  # A +Resource+ is a representation/description of an actual resource (image,
  # sco, pdf, etc...) in a SCORM package.
  class Resource
    attr_accessor :id
    attr_accessor :type
    attr_accessor :scorm_type
    attr_accessor :href
    attr_accessor :metadata
    attr_accessor :files
    attr_accessor :dependencies
    
    def initialize(id, type, scorm_type, href = nil, metadata = nil, files = nil, dependencies = nil)
      raise InvalidManifest, 'Missing resource id' if id.nil?
      raise InvalidManifest, 'Missing resource type' if type.nil?
      breakpoint if scorm_type.nil?
      raise InvalidManifest, 'Missing resource scormType' if scorm_type.nil?
      @id = id.to_s
      @type = type.to_s
      @scorm_type = scorm_type.to_s
      @href = href.to_s || ''
      @metadata = metadata || Hash.new
      @files = files || []
      @dependencies = dependencies || []
    end
    
    def self.from_xml(element)
      metadata = nil
      files = []
      REXML::XPath.each(element, 'file') do |file_el|
        files << element.attribute('xml:base').to_s + file_el.attribute('href').to_s
      end
      dependencies = []
      REXML::XPath.each(element, 'dependency') do |dep_el|
        dependencies << dep_el.attribute('identifierref').to_s
      end
    
      res = self.new(
        element.attribute('identifier'), 
        element.attribute('type'), 
        element.attribute('scormType', 'adlcp') || element.attribute('scormtype', 'adlcp'),
        element.attribute('xml:base').to_s + element.attribute('href').to_s,
        metadata,
        files,
        dependencies)
    end
  end
end