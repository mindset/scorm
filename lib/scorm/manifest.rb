require 'rexml/document'
require 'scorm/metadata'
require 'scorm/organization'
require 'scorm/resource'

module Scorm
  class Manifest
    
    # Versions of the SCORM standard that is supported when running in
    # strict mode. When not running in strict mode, the library will not
    # care about the version specified in the package manifest and will
    # simply try its best to parse the information that it finds.
    SUPPORTED_VERSIONS = ['2004 3rd Edition', 'CAM 1.3', '1.2']
    
    # List of XML and XML Schema files that are part of the manifest for
    # the package.
    MANIFEST_FILES = %w(imsmanifest.xml adlcp_rootv1p2.xsd ims_xml.xsd
       imscp_rootv1p1p2.xsd imsmd_rootv1p2p1.xsd)
    
    # Files that might be present in a package, but that should not be
    # interprested as resources. All files starting with a "." (i.e. hidden
    # files) is also implicitly included in this list.
    RESOURCES_BLACKLIST = [
      '__MACOSX', 'desktop.ini', 'Thumbs.db'
    ].concat(MANIFEST_FILES)
    
    attr_accessor :identifier
    attr_accessor :metadata
    attr_accessor :organizations
    attr_accessor :default_organization
    attr_accessor :resources
    attr_accessor :base_url
    attr_accessor :schema
    attr_accessor :schema_version
  
    def initialize(package, manifest_data)
      @xmldoc = REXML::Document.new(manifest_data)
    
      @package = package
      @metadata = Scorm::Metadata.new
      @organizations = Hash.new
      @resources = Hash.new
      
      # Manifest identifier
      @identifier = @xmldoc.root.attribute('identifier').to_s
    
      # Read metadata
      if metadata_el = REXML::XPath.first(@xmldoc.root, '/manifest/metadata')
        # Read <schema> and <schemaversion>
        schema_el = REXML::XPath.first(metadata_el, 'schema')
        schemaversion_el = REXML::XPath.first(metadata_el, 'schemaversion')
        @schema = schema_el.text.to_s unless schema_el.nil?
        @schema_version = schemaversion_el.text.to_s unless schemaversion_el.nil?
        
        if @package.options[:strict]
          if (@schema != 'ADL SCORM') || (!SUPPORTED_VERSIONS.include?(@schema_version))
            raise InvalidManifest, "Sorry, unsupported SCORM-version (#{schema_el.text.to_s} #{schemaversion_el.text.to_s}), try turning strict parsing off."
          end
        end
      
        # Find a <lom> element...
        lom_el = nil
        if adlcp_location = REXML::XPath.first(metadata_el, 'adlcp:location')
          # Read external metadata file
          metadata_xmldoc = REXML::Document.new(package.file(adlcp_location.text.to_s))
          if metadata_xmldoc.nil? || (metadata_xmldoc.root.name != 'lom')
            raise InvalidManifest, "Invalid external metadata file (#{adlcp_location.text.to_s})."
          else
            lom_el = metadata_xmldoc.root
          end
        else
          # Read inline metadata
          lom_el = REXML::XPath.first(metadata_el, 'lom') ||
                   REXML::XPath.first(metadata_el, 'lom:lom')
        end
      
        # Read lom metadata
        if lom_el
          @metadata = Scorm::Metadata.from_xml(lom_el)
        end
      end
    
      # Read organizations
      if organizations_el = REXML::XPath.first(@xmldoc.root, '/manifest/organizations')
        default_organization_id = organizations_el.attribute('default').to_s
        REXML::XPath.each(@xmldoc.root, '/manifest/organizations/organization') do |el|
          org = Scorm::Organization.from_xml(el)
          @organizations[org.id.to_s] = org
        end
        # Set the default organization
        @default_organization = @organizations[default_organization_id]
        raise InvalidManifest, "No default organization (#{default_organization_id})." if @default_organization.nil?
      else
        raise InvalidManifest, 'Missing organizations element.'
      end
    
      # Read resources
      REXML::XPath.each(@xmldoc.root, '/manifest/resources/resource') do |el|
        res = Scorm::Resource.from_xml(el)
        @resources[res.id] = res
      end
      
      # Read additional resources as assets (this is a fix for packages that
      # don't correctly specify all resource dependencies in the manifest).
      @package.files.each do |file|
        next if File.directory?(file)
        next if RESOURCES_BLACKLIST.include?(File.basename(file))
        next if File.basename(file) =~ /^\./
        next unless self.resources(:with_file => file).empty?
        next unless self.resources(:href => file).empty?
        
        res = Scorm::Resource.new(file, 'webcontent', 'asset', file, nil, [file])
        @resources[file] = res
      end
    
      # Read (optional) base url for resources
      resources_el = REXML::XPath.first(@xmldoc.root, '/manifest/resources')
      @base_url = (resources_el.attribute('xml:base') || '').to_s
    
      # Read sub-manifests
      #REXML::XPath.
    end
  
    def resources(options = nil)
      if (options.nil?) || (!options.is_a?(Hash))
        @resources.values
      else
        subset = @resources.values
        if options[:id]
          subset = subset.find_all {|r| r.id == options[:id].to_s }
        end
        if options[:type]
          subset = subset.find_all {|r| r.type == options[:type].to_s }
        end
        if options[:scorm_type]
          subset = subset.find_all {|r| r.scorm_type == options[:scorm_type].to_s }
        end
        if options[:href]
          subset = subset.find_all {|r| r.href == options[:href].to_s }
        end
        if options[:with_file]
          subset = subset.find_all {|r| r.files.include?(options[:with_file].to_s) }
        end
        subset
      end
    end
    
    def sco(item, attribute = nil)
      resource = self.resources(:id => item.resource_id).first
      resource = (resource && resource.scorm_type == 'sco') ? resource : nil
      return (resource && attribute) ? resource.send(attribute) : resource
    end
  end
end