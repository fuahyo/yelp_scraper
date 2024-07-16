seed_data = {
  'CL' => {#    'CL': ('Chile', (-75.6443953112, -55.61183, -66.95992, -17.5800118954)),
    sw_corner: {lat: -55.61183, long: -75.6443953112},
    ne_corner: {lat: -17.5800118954, long: -66.95992}
  },
  'CZ' => {#    'CZ': ('Czech Rep.', (12.2401111182, 48.5553052842, 18.8531441586, 51.1172677679)),
    sw_corner: {lat: 48.85936, long: 13.82142},
    ne_corner: {lat: 50.7663, long: 15.0543}
  },
  'CA' => {#    'CA': ('Canada', (-140.99778, 41.6751050889, -52.6480987209, 83.23324)),
    sw_corner: {lat: 41.6751050889, long: -140.99778},
    ne_corner: {lat: 83.23324, long: -52.6480987209}
  },
  'SE' => {#    'SE': ('Sweden', (11.0273686052, 55.3617373725, 23.9033785336, 69.1062472602)),
    sw_corner: {lat: 55.3617373725, long: 11.0273686052},
    ne_corner: {lat: 69.1062472602, long: 23.9033785336}
  },
  'AR' => {#    'AR': ('Argentina', (-73.4154357571, -55.25, -53.628348965, -21.8323104794)),
    sw_corner: {lat: -55.25, long: -73.4154357571},
    ne_corner: {lat: -21.8323104794, long: -53.628348965}
  },
  'AT' => {#    'AT': ('Austria', (9.47996951665, 46.4318173285, 16.9796667823, 49.0390742051)),
    sw_corner: {lat: 46.4318173285, long: 9.47996951665},
    ne_corner: {lat: 49.0390742051, long: 16.9796667823}
  },
  'FI' => {#    'FI': ('Finland', (20.6455928891, 59.846373196, 31.5160921567, 70.1641930203)),
    sw_corner: {lat: 59.846373196, long: 20.6455928891},
    ne_corner: {lat: 70.1641930203, long: 31.5160921567}
  },
  'NO' => {#    'NO': ('Norway', (4.99207807783, 58.0788841824, 31.29341841, 80.6571442736)),
    sw_corner: {lat: 58.0788841824, long: 4.99207807783},
    ne_corner: {lat: 80.6571442736, long: 31.29341841}
  },
  'JP' => {#    'JP': ('Japan', (129.408463169, 31.0295791692, 145.543137242, 45.5514834662)),
    sw_corner: {lat: 31.0295791692, long: 129.408463169},
    ne_corner: {lat: 45.5514834662, long: 145.543137242}
  }
}

country_code = ENV['country_code'] rescue nil
if !country_code.nil?
  seed_data = seed_data.select{|key, value| key == country_code }
end

seed_data.each do |code, coords|
  (coords[:sw_corner][:lat].floor..coords[:ne_corner][:lat].ceil).step(0.3).each do |lat|
    (coords[:sw_corner][:long].floor..coords[:ne_corner][:long].ceil).step(0.3).each do |long|

      referer = "https://www.yelp.com/search?start=0&cflt=restaurants&l=g:#{long.to_f},#{lat.to_f},#{long.to_f-1},#{lat.to_f-1}"
      pages << {
        url: "https://www.yelp.com/search/snippet?cflt=restaurants&start=0&l=g:#{long.to_f},#{lat.to_f},#{long.to_f-1},#{lat.to_f-1}",
        page_type: 'seed',
        headers: {
          'accept': 'application/json',
          'accept-language': 'en-US,en;q=0.9,ru;q=0.8',
          'cache-control': 'no-cache',
          'content-type': 'application/json',
          'pragma': 'no-cache',
          'referer': referer,
          'sec-ch-ua': '"Chromium";v="110", "Not A(Brand";v="24", "Microsoft Edge";v="110"',
          'sec-ch-ua-mobile': '?0',
          'sec-ch-ua-platform': 'macOS"',
          'sec-fetch-dest': 'document',
          'sec-fetch-mode': 'navigate',
          'sec-fetch-site': 'none',
          'sec-fetch-user': '?1',
          'x-requested-with': 'XMLHttpRequest',
          "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
        },
        http2: true,
        vars: {
          country: code,
          initial: true
        }
      }
      save_pages(pages) if pages.count > 99
      
      # break
    end
  end
end

# require 'csv'
# rows = CSV.read('input/additional.csv')

# rows.each_with_index do |row, idx|
#   pages << {
#     url: row[0],
#     page_type: 'restaurant',
#     fetch_type: "standard",
#     headers: {
#       "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
#       "Accept-Encoding" => "gzip, deflate, br",
#       "Accept-Language" => "en-US,en;q=0.9",
#       "Cache-Control" => "max-age=0",
#       "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
#     },
#     driver: {
#       name: "additionalRestaurant_1"
#     },
#     http2: true,
#     vars: {
#       country: "SE",
#       position: idx + 1
#     }
#   }
# end

##test
# pages << {
#   url: "https://www.yelp.com/search/snippet?cflt=restaurants&l=g%3A14.4%2C50%2C13.4%2C49&start=0",
#   page_type: 'seed',
#   headers: {
#     'accept': 'application/json',
#     'accept-language': 'en-US,en;q=0.9,ru;q=0.8',
#     'cache-control': 'no-cache',
#     'content-type': 'application/json',
#     'pragma': 'no-cache',
#     'referer': 'https://www.yelp.com/search/snippet?cflt=restaurants&l=g%3A18.0%2C50.7%2C17.0%2C49.7',
#     'sec-ch-ua': '"Chromium";v="110", "Not A(Brand";v="24", "Microsoft Edge";v="110"',
#     'sec-ch-ua-mobile': '?0',
#     'sec-ch-ua-platform': '"Windows"',
#     'sec-fetch-dest': 'empty',
#     'sec-fetch-mode': 'cors',
#     'sec-fetch-site': 'same-origin',
#     'x-requested-with': 'XMLHttpRequest',
#     "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36 Edg/110.0.1587.50",
#   },
#   http2: true,
#   vars: {
#     country: 'CZ',
#     initial: true
#   }
# }
