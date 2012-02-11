require 'Rmagick'

ORIGINALS_DIR = File.join(File.dirname(__FILE__), "..", "images", "originals")
OUTPUT_BASE_DIR = File.join(File.dirname(__FILE__), "..", "public", "images")

class Resizer
  def self.adjust_height(filename, pixels)
  end

  def self.make_output_dir
    Dir.mkdir(OUTPUT_BASE_DIR) unless File.directory?(OUTPUT_BASE_DIR)
  end

  def self.originals
    Dir[ORIGINALS_DIR].each do |file|
      yield file
    end
  end
end
