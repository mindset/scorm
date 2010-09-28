module Scorm::Command
  class Bundle < Base
    def index
      name = args.shift.strip rescue '.'
      unless File.exist?(File.join(File.expand_path(name), 'imsmanifest.xml'))
        raise(CommandFailed, "Invalid package, didn't find any imsmanifest.xml file.")
      end
      
      outname = File.basename(File.expand_path(name)) + '.zip'
      
      require 'zip/zip'
      Zip::ZipFile.open(outname, Zip::ZipFile::CREATE) do |zipfile|
        Scorm::Package.open(name) do |pkg|
          Scorm::Manifest::MANIFEST_FILES.each do |file|
            zipfile.get_output_stream(file) {|f| f.write(pkg.file(file)) }
            display file
          end
          files = pkg.manifest.resources.map {|r| r.files }.flatten.uniq
          files.each do |file|
            zipfile.get_output_stream(file) {|f| f.write(pkg.file(file)) }
            display file
          end
        end
      end
      
      display "Created new SCORM package \"#{outname}\"."
    end
  end
end