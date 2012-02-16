require 'Rmagick'

ORIGINALS_DIR = File.join(File.dirname(__FILE__), "..", "images", "originals")
OUTPUT_BASE_DIR = File.join(File.dirname(__FILE__), "..", "_web")

class Resizer
  include Magick

  def self.adjust_width(filename, output_path, pixels)
    input = File.join(ORIGINALS_DIR, filename)
    image = Image.read(input).first
    image.change_geometry("#{pixels}") do |cols, rows, img|
      image.resize!(cols, rows)
    end
    image.write(File.join(OUTPUT_BASE_DIR, output_path))
  end
end
