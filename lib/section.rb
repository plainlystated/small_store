class Section
  RequiredAttrs = [:description, :image, :title]
  attr_accessor *RequiredAttrs

  def initialize(options)
    RequiredAttrs.each do |attr|
      self.send(:"#{attr}=", options.fetch(attr))
    end
  end

  def empty?
    products.empty?
  end

  def image_path
    "/images/section/#{image}"
  end

  def path
    "/#{slug}/"
  end

  def products
    Products.select {|p| p.section == self}
  end

  def slug
    @title.downcase.gsub(/\W/, '-')
  end
end
