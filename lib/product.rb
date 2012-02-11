class Product
  RequiredAttrs = [:title, :images, :description, :price, :shipping, :section, :blurb]

  attr_accessor *RequiredAttrs

  def initialize(options)
    RequiredAttrs.each do |attr|
      self.send(:"#{attr}=", options.fetch(attr))
    end
  end

  def filename
    "#{slug}.html"
  end

  def path
    "#{section.path}#{slug}.html"
  end

  def slug
    title.downcase.gsub(/\W/, '-')
  end
end
