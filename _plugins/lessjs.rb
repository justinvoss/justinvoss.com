module Jekyll
  
  class LessCssFile < StaticFile

   attr_accessor :lessc_path
   attr_accessor :source_less
   attr_accessor :destination_css

    def write(dest)
      begin
        command = [self.lessc_path, 
                     self.source_less, 
                     self.destination_css
                     ].join(' ')
                     
        puts 'Compiling LESS: ' + command
                     
        `#{command}`
          
        raise "LESS compilation error" if $?.to_i != 0
      end
    end
  end
  
# Expects a lessc: key in your _config.yml file with the path to a local less.js/bin/lessc
# Less.js will require node.js to be installed
  class LessJsGenerator < Generator
    safe true
    priority :low
    
    def generate(site)
      src_root = site.config['source']
      dest_root = site.config['destination']
      less_ext = /\.less$/i
      
      raise "Missing 'lessc' path in site configuration" if !site.config['lessc']
      
      # static_files have already been filtered against excludes, etc.
      site.static_files.dup.each do |sf|
        next if not sf.path =~ less_ext
        
        less_path = sf.path
        css_path = less_path.gsub(less_ext, '.css').gsub(src_root, dest_root)
        css_dir = File.dirname(css_path)
        css_dir_relative = css_dir.gsub(dest_root, '')
        css_name = File.basename(css_path)
        
        FileUtils.mkdir_p(css_dir)

        # Add this output file so it won't be cleaned
        static_file = LessCssFile.new(site, site.source, css_dir_relative, css_name)
        static_file.lessc_path = site.config['lessc']
        static_file.source_less = less_path
        static_file.destination_css = css_path
        site.static_files << static_file
      end
    end
    
  end
end
