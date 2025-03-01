per_page = 500
last_id = ''
locations = []

while true
  query = {
    '_id' => {'$gt' => last_id},
    '$orderby' => [{'_id' => 1}]
  }
  records = find_outputs("locations", query, 1, per_page)

  records.each do |location|
    tag = []
    unless location['restaurant_tags'].nil?
      location['restaurant_tags'].each do |tg|
        if !tag.include? tg
          tag.append(tg)
        end
      end
      location['restaurant_tags'] = tag
    end
    
    # if location['main_cuisine'].nil?
    #   require 'byebug'; byebug
    # end
    unless location['main_cuisine'].nil?
      if location['main_cuisine'].include?'&amp;'
        location['main_cuisine'] = location['main_cuisine'].gsub('&amp;','')
      end
    end
    # unless location['restaurant_delivery_zones'].nil?
    #   location['restaurant_delivery_zones'].first['currency'] = ENV['currency_code']
    # end 
    
    # unless location['restaurant_post_code'].nil?
    #   location['restaurant_post_code'] = nil if location['restaurant_post_code'].empty?
    # end

    # unless location['free_field'].nil?
    #   if location['free_field']['website'].nil? || location['free_field'].empty?
    #     location['free_field'] = nil
    #   end
    # end
    location['number_of_ratings'] = location['number_of_ratings'].to_f
    location['restaurant_rating'] = nil if location['restaurant_rating'] == 0
    location['number_of_ratings'] = nil if location['number_of_ratings'] == 0

    outputs << location

    save_outputs(outputs) if outputs.count > 99
  end

  break if records.nil? || records.count < 1

  last_id = records.last['_id']
end