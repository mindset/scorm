module Scorm
  
  # The +Metadata+ class holds meta data associated with a SCORM package in a 
  # hash like structure. The +Metadata+ class reads a LOM (Learning Object 
  # Metadata) structure and stores the data in categories. A +Category+ can
  # contain any number of +DataElement+s. A +DataElement+ behaves just like
  # a string but can contain the same value in many different languages, 
  # accessed by the DataElement#value (or DataElement#to_s) method by 
  # specifying the language code as the first argument.
  #
  # Ex.
  #
  #   <tt>pkg.manifest.metadata.general.class -> Metadata::Category</tt>
  #   <tt>pkg.manifest.metadata.general.title.class -> Metadata::DataElement</tt>
  #   <tt>pkg.manifest.metadata.general.title.value -> 'My course'</tt>
  #   <tt>pkg.manifest.metadata.general.title.value('sv') -> 'Min kurs'</tt>
  #
  class Metadata < Hash
    
    def self.from_xml(element)
      metadata = self.new
      element.elements.each do |category_el|
        category = Category.from_xml(category_el)
        metadata.store(category_el.name.to_s, category)
      end
      return metadata
    end
    
    def method_missing(sym)
      self.fetch(sym.to_s, nil)
    end
    
    class Category < Hash
      
      def self.from_xml(element)
        category = Scorm::Metadata::Category.new
        element.elements.each do |data_el|
          category[data_el.name.to_s] = DataElement.from_xml(data_el)
        end
        return category
      end
      
      def method_missing(sym, *args)
        data_element = self.fetch(sym.to_s, nil)
        if data_element.is_a? DataElement
          data_element.value(args.first)
        else
          data_element
        end
      end
    end
    
    class DataElement
      def initialize(value = '', default_lang = nil)
        if value.is_a? String
          @langstrings = Hash.new
          @langstrings['x-none'] = value
          @default_lang = 'x-none'
        elsif value.is_a? Hash
          @langstrings = value.dup
          @default_lang = default_lang || 'x-none'
        end
      end
      
      def self.from_xml(element)
        if element.elements.size == 0
          return self.new(element.text.to_s)
          
        elsif element.get_elements('value').size != 0
          value_el = element.get_elements('value').first
          return self.from_xml(value_el)
          
        elsif element.get_elements('langstring').size != 0
          langstrings = Hash.new
          default_lang = nil
          element.each_element('langstring') do |ls|
            default_lang = ls.attribute('xml:lang').to_s if default_lang.nil?
            langstrings[ls.attribute('xml:lang').to_s || 'x-none'] = ls.text.to_s
          end
          return self.new(langstrings, default_lang)
          
        else
          return Category.from_xml(element)
          
        end
      end
      
      def value(lang = nil)
        if lang.nil?
          (@langstrings && @default_lang) ? @langstrings[@default_lang] : ''
        else
          (@langstrings) ? @langstrings[lang] || '' : ''
        end
      end
      
      alias :to_s :value
      alias :to_str :value
    end
  end
end