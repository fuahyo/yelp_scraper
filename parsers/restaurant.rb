code = "
  await sleep(3000);
"
parsable = true
newName = false

if false
else
  def uuid_v3(uuid_namespace, name)
    version = 3

    hash = Digest::MD5.new
    hash.update(uuid_namespace)
    hash.update(name)

    ary = hash.digest.unpack("NnnnnN")
    ary[2] = (ary[2] & 0x0FFF) | (version << 12)
    ary[3] = (ary[3] & 0x3FFF) | 0x8000

    "%08x-%04x-%04x-%04x-%04x%08x" % ary
  end
  
  html = Nokogiri::HTML(content)
  json = html.search('script[type="application/ld+json"]').inject({}){|a,b| a.merge JSON.parse(b)} rescue nil
  json2 = json

  if json.nil?
    html.css('script[type="application/ld+json"]').each do |js|
      body = JSON.parse(js.text)
      json = body if body['@type'] == "Restaurant" rescue nil
    end
  end

  if !json['address']
    search_script = html.css("script").find{|s| s.text =~ /ItemList/}
    json = JSON.parse(search_script)['itemListElement'][0]['contentLocation'] rescue nil

    if json.nil?  
      json3 = {}
      jsonHtmlSearch = html.search('script[type="application/json"]')
      jsonHtmlSearch.each do |script|
        content = script.content
        content.gsub!(/<!--(.*?)-->/m, '\1')
        content.gsub!("&quot;", '"')
        begin
          parsed_content = JSON.parse(content)
          if parsed_content.is_a?(Hash)
            json3.merge!(parsed_content)
          else
            puts "Skipping non-hash JSON content"
          end
        rescue JSON::ParserError => e
          puts "Skipping invalid JSON: #{e.message}"
        end
      end
      # json = json2
      json = json2.merge(json3['legacyProps']['bizDetailsProps'])
      target_key_location = json3.keys.find { |key| key.match(/\$ROOT_QUERY\.business\({\"encid\":\".*\"}\)\.location\.address/) }
      target_key_telephone = json3.keys.find { |key| key.match(/\$ROOT_QUERY\.business\({\"encid\":\".*\"}\)\.phoneNumber/) }
      target_key_rating = json3.keys.find { |key| key.match(/\$ROOT_QUERY\.business\({\"encid\":\".*\"}\)/) }
      target_key_alias = json3.keys.find { |key| key.match(/\$ROOT_QUERY\.business\({\"encid\":\".*\"}\)\.categories\.0/) }
      json = json.merge("location" => json3[target_key_location])
      json = json.merge("telephone" =>json3[target_key_telephone]['formatted'])
      json = json.merge("rating" =>json3[target_key_rating]['rating'])
      json = json.merge("reviewCount" =>json3[target_key_rating]['reviewCount'])
      json = json.merge("priceRange" =>json3[target_key_rating]['priceRange'])
      json = json.merge("servesCuisine" =>json3[target_key_alias]['title'])

      newName = true
    end 
  end

  addressCountry = json['address']['addressCountry'] rescue nil
  addressCountry = json['gaDimensions']['global']['content_country'][1] if addressCountry.nil? || addressCountry.empty?
  unless addressCountry.nil?  
    if addressCountry != page['vars']['country']
      outputs << {
        _collection: "another_country_restaurant",
        country: addressCountry,
        url: page['url']
      }
      parsable = false
    end
  end
  uid = html.at('meta[name="yelp-biz-id"]')['content'] rescue nil

  
  if parsable
    if !json.nil?
      name = json['name']
      name = json['bizDetailsPageProps']['businessName'] if newName

      street_1 = json['address']['streetAddress'].gsub(/\s+/, ' ') rescue nil
      street_1 = json['location']['addressLine1'] if street_1.nil?
      
      city = json['address']['addressLocality'] rescue nil
      city = json['location']['city'] if city.nil?
      
      state = json['address']['addressRegion'] rescue nil
      state = json['location']["regionCode"] if state.nil?
      
      zip = json['address']['postalCode'].gsub('〒', '') rescue nil
      zip = json['location']['postalCode'].gsub('〒', '') if zip.nil?
      
      unless zip.nil?
        if zip.empty?
          zip = nil
        end
      end 
      country = json['address']['addressCountry'] rescue nil
      country = json['location']["formatted"].split("\n")[2].strip if country.nil? && json['location']
      
      phone = json['telephone'] rescue nil
      
      rating = json.dig('aggregateRating', 'ratingValue') || json['rating'] rescue nil
      
      reviews_count = json.dig('aggregateRating', 'reviewCount') || json['reviewCount'] || 0
        
      price_category = json['priceRange']
      
      main_cuisine = json['servesCuisine']

      if main_cuisine.is_a?(Array)
        main_cuisine = main_cuisine.first
      end

      unless main_cuisine.nil?
        if main_cuisine.include?','
          main_cuisine = main_cuisine.split(',').first
        end
      end
        # require 'byebug'
    end
    # byebug

    cuisines = html.search('span.category-str-list a').map{|cat| cat.text.strip.gsub(/\\u([a-f0-9]{4,5})/i){ [$1.hex].pack('U') }}.uniq rescue []

    if cuisines.nil? || cuisines.count == 0
      cuisines = html.search('div:has(h1) ~ span a').map{|a| a.text}
    end
    cuisines.shift if cuisines.first == 'Unclaimed'
    
    
    if rating.nil?
      rating = html.at('div.photoHeader__373c0__1lZx8 div.i-stars__373c0___sZu0')['aria-label'][/([\d\.]+) star/, 1].to_f rescue nil
      rating ||= html.at('div.arrange-unit__373c0__3S8rT.arrange-unit-fill__373c0__24Gfj div.i-stars__373c0___sZu0')['aria-label'][/([\d\.]+) star/, 1].to_f rescue nil
      rating ||= Float(html.at('div[class*="photoHeader"] div[class*="five-stars"]')['aria-label'][/([\d\.]+) star/, 1]) rescue nil
      rating ||= Float(html.at('main#main-content:first-child div[class*="five-stars"]')['aria-label'][/([\d\.]+) star/, 1]) rescue nil
      rating ||= Float(html.at('yelp-react-root > div > div[class*="arrange"] div[class*="five-stars"]')['aria-label'][/([\d\.]+) star/, 1]) rescue nil

      
      reviews_count = html.at('div.photoHeader__373c0__1lZx8 span.css-bq71j2:contains("review")').text[/(\d+) review/, 1].to_i rescue nil
      reviews_count ||= html.at('div.arrange-unit__373c0__3S8rT.arrange-unit-fill__373c0__24Gfj span.css-1h1j0y3:contains("review")').text[/(\d+) review/, 1].to_i rescue nil
      reviews_count ||= Integer(html.at('div#reviews div[class*="rating-text"] p').text[/(\d+) review/i, 1]) rescue nil
      reviews_count ||= Integer(html.css('div[class*="photoHeader"] span').find{|t| t.text =~ /\d+ review/i}.text[/(\d+) review/, 1]) rescue nil
      reviews_count ||= Integer(html.css('main#main-content:first-child span').find{|t| t.text =~ /\d+ review/i}.text[/(\d+) review/, 1]) rescue nil
    end

    lat, long = html.at('a.biz-map-directions img[alt="Map"]')['src'].scan(/center=([\-\.\d]+)%2C([\-\.\d]+)&/).first rescue [nil, nil]
    lat, long = html.at('section:contains("Location") img[alt="Map"]')['src'].scan(/center=([\-\.\d]+)%2C([\-\.\d]+)&/).first rescue [nil, nil] if lat.nil?
    lat, long = html.at('section[aria-label="Location & Hours"] img[alt="Map"]')['src'].scan(/center=([\-\.\d]+)%2C([\-\.\d]+)&/).first rescue [nil, nil] if lat.nil? || lat.empty?

    hours_sel = html.search('table.table--simple__373c0__3QsR_.hours-table__373c0__2YHlD tr:has(th)')
    hours = hours_sel.inject({}) do |a,b|
      key = b.at('th').text[0..2]
      value = b.search('td ul li p').map(&:text).map do |range|
        if range =~ /24 hours/i
          '0000-0000'
        else
          range.split('-').map do |d|
            time = Time.parse(Nokogiri::HTML(d.strip).text).strftime("%H%M")
          end.join('-')
        end
      end rescue nil
      a.merge({key => value})
    end.delete_if{|a,b| b.nil? || b.empty?}

    if hours_sel.empty?
      hours = html.search('table[class*="hours-table"] tr:has(th)').inject({}) do |a,b|
        key = b.at('th').text[0..2]
        value = b.search('td ul li p').map(&:text).map do |range|
          if range =~ /24 hours/i
            '0000-0000'
          else
            range.split('-').map do |d|
              time = Time.parse(Nokogiri::HTML(d.strip).text).strftime("%H%M")
            end.join('-')
          end
        end rescue nil
        a.merge({key => value})
      end.delete_if{|a,b| b.nil? || b.empty?}
    end

    # delivery = html.at('div:has(span:contains("Offers Delivery"))').at('span:contains("Yes")') != nil rescue false

    uuid = uuid_v3("yelp_#{page['vars']['country'].downcase}", uid)
    id_dedup = "#{CGI.unescapeHTML(name)}_#{street_1}_#{city}"

    tags_raw = html.to_html.scan(/0\.properties\.\d+.+?displayText&quot;:&quot;(.+?)&quot;/).flatten
    tags = []
    tags_raw.each do |tag|
      if !tags.include? tag
        tags.append(tag)
      end
    end
    delivery = tags.include?('Offers Delivery')

    cuisines = nil if cuisines.empty?
    cuisines_formated = {}
    cuisines&.uniq.each_with_index do |cuisine, index|
      cuisines_formated["cuisine#{index + 1}"] = cuisine
    end rescue {}
    # require 'byebug';byebug

    # zip = nil if zip.empty?
    zip = nil if zip.nil?
    zip ||= nil if zip == 0

    free_field = nil
    website = html.search('div:has(p:contains("Business website"))').last.text.gsub('Business website', "http://www.") rescue nil
    if !website.nil?
      free_field = {website: website}
    end

    if addressCountry == page['vars']['country']
      if main_cuisine.nil?
        location = {
          _collection: 'non-related',
          _id: id_dedup,
          date: Time.parse(page['fetched_at']).strftime('%Y%m%d %H:%M:%S'),
          lead_id: uuid,
          url: page['url'],
          restaurant_name: CGI.unescapeHTML(name), 
  
          price_category: price_category,
          # restaurant_address: street_1.empty? ? nil : street_1,
          restaurant_address: street_1.nil? ? nil : (street_1.empty? ? nil : street_1),
          restaurant_city: city.empty? ? nil : city,
          restaurant_area: state.nil? || state.empty? ? nil : state,
          restaurant_post_code: zip,
          restaurant_country: country,
          restaurant_lat: (Float(lat) rescue nil),
          restaurant_long: (Float(long) rescue nil),
          phone_number: (phone&.empty? ? nil : phone),
          restaurant_delivers: delivery,
          # restaurant_overall_rating: (html.at('span.overallRating').text.strip rescue nil),
          restaurant_rating: (rating ? rating.to_i : nil),
          restaurant_position: nil,
          number_of_ratings: reviews_count,
          main_cuisine: main_cuisine,
          cuisine_name: cuisines&.uniq,
          opening_hours: (hours&.empty? ? nil : hours),
          restaurant_tags: (tags&.empty? ? nil : tags.map{|t| CGI.unescapeHTML(t)}),
          restaurant_delivery_zones: delivery ? [{"delivery_zone": nil,"minimum_order_value": nil,"delivery_fee": nil,"currency": "#{ENV['currency_code']}"}] : nil,
          free_field: free_field
        }
        outputs << location
        save_outputs outputs if outputs.length > 99
      else
        location = {
          _collection: 'locations',
          _id: id_dedup,
          date: Time.parse(page['fetched_at']).strftime('%Y%m%d %H:%M:%S'),
          lead_id: uuid,
          url: page['url'],
          restaurant_name: CGI.unescapeHTML(name), 

          price_category: price_category,
          # restaurant_address: street_1.empty? ? nil : street_1,
          restaurant_address: street_1.nil? ? nil : (street_1.empty? ? nil : street_1),
          restaurant_city: city.empty? ? nil : city,
          restaurant_area: state.nil? || state.empty? ? nil : state,
          restaurant_post_code: zip, #zip.nil? ? nil : zip,
          restaurant_country: country,
          restaurant_lat: (Float(lat) rescue nil),
          restaurant_long: (Float(long) rescue nil),
          phone_number: (phone&.empty? ? nil : phone),
          restaurant_delivers: delivery,
          restaurant_rating: (rating ? rating.to_f : nil),
          restaurant_position: nil,
          number_of_ratings: reviews_count.to_f,
          main_cuisine: main_cuisine,
          cuisine_name: cuisines_formated,
          opening_hours: (hours&.empty? ? nil : hours),
          restaurant_tags: (tags&.empty? ? nil : tags.map{|t| CGI.unescapeHTML(t)}),
          restaurant_delivery_zones: delivery ? [{"delivery_zone": nil,"minimum_order_value": nil,"delivery_fee": nil,"currency": "#{ENV['currency_code']}"}] : nil,
          free_field: free_field
        }
        outputs << location
        save_outputs outputs if outputs.length > 99

        pages << {
          url: page['url'].gsub(/\/$/, '') + "/props",
          page_type: 'props',
          fetch_type: "standard",
          priority: 500,
          headers: {
            'accept': 'application/json',
            'accept-language': 'en-US,en;q=0.9,ru;q=0.8',
            'cache-control': 'no-cache',
            'content-type': 'application/json',
            'pragma': 'no-cache',
            'referer': page['url'],
            'sec-ch-ua': '"Chromium";v="110", "Not A(Brand";v="24", "Microsoft Edge";v="110"',
            'sec-ch-ua-mobile': '?0',
            'sec-ch-ua-platform': '"Windows"',
            'sec-fetch-dest': 'empty',
            'sec-fetch-mode': 'cors',
            'sec-fetch-site': 'same-origin',
            'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36',
            'x-requested-with': 'XMLHttpRequest'
          },
          http2: true,
          vars: page['vars'].merge({
            "parent_gid" => page['gid'],
            # "location" => location
          }),
        } 
        save_pages pages if pages.count > 99
      end
    end
  end
end
