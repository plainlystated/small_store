Products = []
Dir[File.join(File.dirname(__FILE__), "products", "*.rb")].each do |file|
  require file
end
