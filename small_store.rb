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
autoload :AssetServers, File.expand_path(File.join(File.dirname(__FILE__), 'config', 'asset_servers.rb'))

class ViewHelper
  def initialize(subject = nil)
    @subject = subject || OpenStruct.new
  end

  def asset(path)
    @@assets_index ||= -1
    @@assets_index = (@@assets_index + 1) % AssetServers.size

    "#{AssetServers[@@assets_index]}#{path}"
  end

  def method_missing(method, *args, &block)
    @subject.send(method, *args, &block)
  end
end

def render_with_layout(file, context = nil)
  context ||= OpenStruct.new
  view_helper = ViewHelper.new(context)

  template = Tilt.new(LAYOUT_TEMPLATE)
  template.render(view_helper) do
    Tilt.new(file).render(view_helper)
  end
end

def delete_previous_generation
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
    FileUtils.mkdir_p(File.join(OUTPUT_DIR, section.path))
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
    FileUtils.mkdir_p(File.dirname(output_file))
    if File.exists?(output_file)
      raise "duplicate file #{output_file}"
    end

    File.open(output_file, "w") do |f|
      f.write(render_with_layout(PRODUCT_TEMPLATE, product))
    end
  end
end

def _minify(type, output_filename = nil, files = nil)
  content_dir = type == "css" ? "styles" : type
  output_dir = "#{OUTPUT_DIR}/#{content_dir}/min"
  output_filename ||= "creativeretrospection-min.#{type}"
  output_filename = "#{output_dir}/#{output_filename}"
  Dir.mkdir(output_dir) unless File.exists?(output_dir)

  if files
    content = "cat #{files.map {|f| "#{OUTPUT_DIR}/#{content_dir}/#{f}"}.join(" ")}"
  else
    content = "cat #{OUTPUT_DIR}/#{content_dir}/*#{type}"
  end
  yui_compress = "java -jar lib/yuicompressor-2.4.7.jar --type #{type}"

  lines_before = `#{content} | wc -c`.to_i
  `#{content} | #{yui_compress} > #{output_filename}`
  lines_after = `cat #{output_filename} | wc -c`.to_i

  improvement = (lines_before - lines_after).to_f / lines_before * 100
  puts "Minified #{type.upcase} by #{"%.2f" % improvement}%"
end

def minify
  js_minimal_files = %w[
    shoppingCart.js
    jquery-1.7.1.min.js
    simpleCart.min.js
  ]
  _minify('js', 'creativeretrospection-minimal-min.js', js_minimal_files)
  _minify('js')
  _minify('css')
end

def resize_section_images
  FileUtils.mkdir_p(File.join(OUTPUT_DIR, "images", "section"))

  Sections.each do |name, section|
    Resizer.adjust_width(section.image, section.image_path, 300)
  end
  Resizer.adjust_width("me.jpg", "/images/me.jpg", 300)
  puts "Resized section images"
end

def resize_product_images
  _resize_product_teaser_images
  _resize_product_page_images
  puts "Resized product images"
end

def _resize_product_page_images
  FileUtils.mkdir_p(File.join(OUTPUT_DIR, "images", "product", "thumbs"))
  FileUtils.mkdir_p(File.join(OUTPUT_DIR, "images", "product", "large"))

  Products.each do |product|
    product.images.each do |image|
      Resizer.adjust_width(image, "/images/product/thumbs/#{image}", 120)
      Resizer.adjust_width(image, "/images/product/large/#{image}", 550)
    end
  end
end

def _resize_product_teaser_images
  FileUtils.mkdir_p(File.join(OUTPUT_DIR, "images", "product", "teaser"))

  Products.each do |product|
    Resizer.adjust_height(product.images.first, product.teaser_image_path, 150)
  end
end

delete_previous_generation
copy_public_with_templating
generate_section_pages
generate_product_pages

minify

resize_section_images
resize_product_images

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
