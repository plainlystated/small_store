require 'etsy'

OUTPUT_FILE = File.join(File.dirname(__FILE__), "config", "products", "from_etsy.rb")

Etsy.api_key = '98n6n3bh8132nk2uu8dgbe8v'
Etsy.environment = :production

user = Etsy.user('plainlystated')

File.open(OUTPUT_FILE, "w") do |out|
  # listing = user.shop.listings.first
  listings = user.shop.listings
  listings.each do |listing|
    description = listing.description.split(/[\n\r]/).reject(&:empty?)
    images = listing.images.map(&:full)
    out.puts <<END
Products << Product.new(
  :title => "#{listing.title}",
  :section => Sections[:state_mirrors],
  :images => #{images},
  :blurb => "",
  :description => #{description},
  :price => #{listing.price.gsub(/\..*/, '')},
  :shipping => {},
  :size => nil
)
END
  end

  puts "Imported #{listings.size} listings"
end

