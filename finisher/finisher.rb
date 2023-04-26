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
    cuisines = {}
    location['cuisine_name'].each_with_index do |cuisine, index|
        cuisines["cuisine#{index + 1}"] = cuisine
    end rescue {}
    location['cuisine_name'] = cuisines

    unless location['restaurant_delivery_zones'].nil?
      location['restaurant_delivery_zones'].first['currency'] = ENV['currency_code']
    end 
    
    # unless location['restaurant_post_code'].nil?
    #   location['restaurant_post_code'] = nil if location['restaurant_post_code'].empty?
    #   post_code = location['restaurant_post_code'].gsub(/[A-Za-z]/,"").gsub(' ','').to_f
    #   location['restaurant_post_code'] = post_code
    # end

    unless location['free_field'].nil?
      if location['free_field']['website'].nil? || location['free_field'].empty?
        location['free_field'] = nil
      end
    end

    location['restaurant_post_code'] = nil if location['restaurant_post_code'] == 0
    outputs << location

    save_outputs(outputs) if outputs.count > 99
  end

  break if records.nil? || records.count < 1

  last_id = records.last['_id']
end