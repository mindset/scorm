#--
# TODO: items should be read as an hierarchy.
#
# TODO: imsss:sequencing and adlnav:presentation should be parsed and read.
#
# TODO: read <item><metadata>...</metadata></item>.
#++

module Scorm
  # The +Organization+ class holds data about the organization of a SCORM
  # package. An organization contains an id, title and any number of +items+.
  # An +Item+ are (in most cases) the same thing as a SCO (Shareable Content 
  # Object).
  class Organization
    attr_accessor :id
    attr_accessor :title
    attr_accessor :items
    
    def initialize(id, title, items)
      raise InvalidManifest, 'missing organization id' if id.nil?
      @id = id.to_s
      @title = title.to_s
      @items = items
    end
    
    def self.from_xml(element)
      id = element.attribute('identifier').to_s
      title = element.get_elements('title').first.text.to_s if element.get_elements('title').first
      items = []
      REXML::XPath.each(element, 'item') do |item_el|
        items << Item.from_xml(item_el)
      end
      return self.new(id, title, items)
    end
    
    # An item has an id, title, and (in some cases) a parent item. An item is
    # associated with a resource, which in most cases is a SCO (Shareable 
    # Content Object) resource.
    class Item
      attr_accessor :id
      attr_accessor :title
      attr_accessor :isvisible
      attr_accessor :parameters
      attr_accessor :resource_id
      attr_accessor :children
      attr_accessor :time_limit_action
      attr_accessor :data_from_lms
      attr_accessor :completion_threshold
      
      def initialize(id, title, isvisible = true, parameters = nil, resource_id = nil, children = nil)
        @id = id.to_s
        @title = title.to_s
        @isvisible = isvisible || true
        @parameters = parameters
        @resource_id = resource_id
        @children = children if children.is_a? Array
      end
      
      def self.from_xml(element)
        item_id = element.attribute('identifier').to_s
        item_title = element.get_elements('title').first.text.to_s if element.get_elements('title').first
        item_isvisible = (element.attribute('isvisible').to_s == 'true')
        item_parameters = element.attribute('parameters').to_s
        children = []
        if element.get_elements('item').empty?
          resource_id = element.attribute('identifierref').to_s
        else
          element.each_element('item') do |item_el|
            child_item = self.from_xml(item_el)
            children << child_item
          end
        end
        return self.new(item_id, item_title, item_isvisible, item_parameters, resource_id, children)
      end
    end
  end
end