module Scorm::Command
  class Check < Base
    def index
      package = args.shift.strip rescue ''
      raise(CommandFailed, "Invalid package.") if package == ''

      Scorm::Package.open(package, :dry_run => true) do |pkg|
        display "Checking package \"#{File.basename(package)}\""
        display ""
        display "== UUID =="
        display "Identifier: #{pkg.manifest.identifier}"
        display ""
        display "== Manifest =="
        %w(imsmanifest.xml adlcp_rootv1p2.xsd ims_xml.xsd
           imscp_rootv1p1p2.xsd imsmd_rootv1p2p1.xsd).each do |file|
         if pkg.exists?(file)
           display "#{file} -> OK"
          else
            display "#{file} -> Missing"
          end
        end
        display ""
        display "== Organizations =="
        pkg.manifest.organizations.each do |id, organization|
          if organization == pkg.manifest.default_organization
            display "#{organization.title} (default)"
          else
            display "#{organization.title}"
          end
        end
        display ""
        display "== Resources =="
        pkg.manifest.resources.each do |resource|
          display "#{resource.href} (#{resource.type}, #{resource.scorm_type}):"
          resource.files.each do |file|
            if pkg.exists?(file)
              display "  - #{file} -> OK"
            else
              display "  - #{file} -> Missing"
            end
          end
        end
      end
    end
  end
end