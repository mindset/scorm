SCORM is a Ruby library for reading and extracting Shareable Content Object
Reference Model (SCORM) files. SCORM is a standardized package format used
mainly by e-learning software to help with the exchange of course material
between systems in an interoperable way. This gem supports SCORM 1.2 and SCORM
2004.

The gem can both be used as a library in your application or as a command line
tool. This gem does NOT handle the run-time part of the SCORM standard, only
the so called "Content Aggregation Model".


Usage
-----

    create <name>               # create a new package skeleton
    bundle [<path to directory>]# creates a package from the current directory
    check <path to zip file>    # runs a test suite against your package
    extract <path to zip file>  # extracts and checks the specified package


Example Workflow
----------------

    scorm create mypackage        # Create a new package skeleton
    cd mypackage                  # 
    scorm bundle                  # Create .zip file from current directory
    scorm check mypackage.zip     # Verify that the package is valid SCORM
    scorm extract mypackage.zip   # Extract the mypackage.zip package
    

Installation
------------

    gem install scorm

To use the SCORM gem as a library in your application to extract and read
SCORM files you can simply require the 'scorm/package' file.

    require 'scorm/package'
    
    Scorm::Package.open('mypackage.zip') do |pkg|
      # Read stuff from the package...
      puts pkg.manifest.identifier
      puts pkg.manifest.default_organization.title
      puts pkg.manifest.metadata.general.title.value
      pkg.manifest.resources.each do |resource|
        puts resource.href
        puts resource.scorm_type
        if pkg.exists?(resource.files.first)
          puts resource.files.first
          puts pkg.file(resource.files.first)
        end
      end
      # etc...
    end

See the RDOC documentation for more info about what you can read from the
package manifest.
    

About
-----

Created and maintained by Niklas Holmgren.
Released under the MIT license. http://github.com/mindset/scorm
