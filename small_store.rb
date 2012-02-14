require 'fileutils'
require 'erb'
require 'tilt'
require 'ostruct'

OUTPUT_DIR = File.expand_path(File.join(File.dirname(__FILE__), "_web"))
LAYOUT_TEMPLATE = File.expand_path(File.join(File.dirname(__FILE__), 'views', 'layout.html.erb'))
PRODUCT_TEMPLATE = File.expand_path(File.join(File.dirname(__FILE__), 'views', 'product.html.erb'))
SECTION_TEMPLATE = File.expand_path(File.join(File.dirname(__FILE__), 'views', 'section.html.erb'))

autoload :Resizer, File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'resizer.rb'))
autoload :Product, File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'product.rb'))
autoload :Section, File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'section.rb'))

autoload :Sections, File.expand_path(File.join(File.dirname(__FILE__), 'config', 'sections.rb'))
autoload :Products, File.expand_path(File.join(File.dirname(__FILE__), 'config', 'products.rb'))

autoload :AboutMe, File.expand_path(File.join(File.dirname(__FILE__), 'config', 'about_me.rb'))
autoload :GoogleAnalyticsAccount, File.expand_path(File.join(File.dirname(__FILE__), 'config', 'google_analytics_account.rb'))

def render_with_layout(file, context = {})
  template = Tilt.new(LAYOUT_TEMPLATE)
  template.render(context) do
    Tilt.new(file).render(context)
  end
end

def delete_previous_generation
  puts "Deleting old files from #{OUTPUT_DIR}"
  Dir[File.join(OUTPUT_DIR, "*")].each do |file|
    puts " - #{file}"
    FileUtils.rm_rf file
  end
end

def copy_public_with_templating
  Dir.chdir(File.join(File.dirname(__FILE__), 'public')) do
    Dir["**/*"].each do |input_file|
      if File.directory?(input_file)
        Dir.mkdir(File.join(OUTPUT_DIR, input_file))
      elsif input_file =~ /\.coffee$/
        puts "compiling coffeescript"
        puts `coffee -c #{input_file}`
        js_file = input_file.sub(/coffee$/, 'js')

        FileUtils.mv js_file, File.join(OUTPUT_DIR, js_file)
      elsif input_file =~ /\.erb$/
        if input_file == "index.html.erb"
          context = OpenStruct.new(:min_js_includes => true)
        else
          context = OpenStruct.new
        end
        File.open(File.join(OUTPUT_DIR, input_file.sub(/\.erb$/, '')), "w") do |output_file|
          output_file.write render_with_layout(input_file, context)
        end
      else
        FileUtils.cp input_file, File.join(OUTPUT_DIR, input_file)
      end
    end
  end
end

def generate_section_pages
  Sections.each do |label, section|
    Dir.mkdir(File.join(OUTPUT_DIR, section.path))
    output_file = File.join(OUTPUT_DIR, section.path, "index.html")
    if File.exists?(output_file)
      raise "duplicate file #{output_file}"
    end

    File.open(output_file, "w") do |file|
      file.write render_with_layout(SECTION_TEMPLATE, section)
    end
  end
end

def generate_product_pages
  Products.each do |product|
    output_file = File.join(OUTPUT_DIR, product.path)
    if File.exists?(output_file)
      raise "duplicate file #{output_file}"
    end

    File.open(output_file, "w") do |f|
      f.write(render_with_layout(PRODUCT_TEMPLATE, product))
    end
  end
end

def minify
  js_content = "cat #{OUTPUT_DIR}/js/*js"
  lines_before = `#{js_content} | wc -c`.to_i
  `#{js_content} | java -jar lib/yuicompressor-2.4.7.jar --type js > #{OUTPUT_DIR}/js/creativeretrospection-min.js`
  lines_after = `cat #{OUTPUT_DIR}/js/creativeretrospection-min.js | wc -c`.to_i

  improvement = (lines_before - lines_after).to_f / lines_before * 100
  puts "Minified JS by #{"%.2f" % improvement}%"

  css_content = "cat #{OUTPUT_DIR}/styles/*css"
  lines_before = `#{css_content} | wc -c`.to_i
  `#{css_content} | java -jar lib/yuicompressor-2.4.7.jar --type css > #{OUTPUT_DIR}/styles/creativeretrospection-min.css`
  lines_after = `cat #{OUTPUT_DIR}/styles/creativeretrospection-min.css | wc -c`.to_i

  improvement = (lines_before - lines_after).to_f / lines_before * 100
  puts "Minified CSS by #{"%.2f" % improvement}%"
end

delete_previous_generation
copy_public_with_templating
generate_section_pages
generate_product_pages

minify

# resize_section_images
#resize_product_images

if ARGV[0] == "server"
  require 'webrick'
  include WEBrick

  port = 9090

  puts "URL: http://#{Socket.gethostname}:#{port}"

  s = HTTPServer.new(
    :Port            => port,
    :DocumentRoot    => OUTPUT_DIR
  )

  trap("INT"){ s.shutdown }
  s.start
end
