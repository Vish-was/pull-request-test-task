require 'nokogiri'
require 'open-uri'
require 'csv'

url = 'https://github.com/rails/rails'
html = URI.open(url)
doc = Nokogiri::HTML(html)

search_tab = doc.search('[@id="pull-requests-tab"]')

pull_request_tab_url  = "https://github.com#{search_tab.first.attributes['href'].value}"
pull_request_tab_html = URI.open(pull_request_tab_url)
doc_pull_request_tab  = Nokogiri::HTML(pull_request_tab_html)

total_page_css = doc_pull_request_tab.css('.current')
total_page = total_page_css.first.attributes['data-total-pages'].value.to_i

urls = []

for i in 1..total_page
	per_page_pull_urls = pull_request_tab_url + "?page=#{i}"
	per_page_pull_html = URI.open(per_page_pull_urls)
	per_page_response = Nokogiri::HTML(per_page_pull_html)
	per_page_data = per_page_response.css('.Box-row')

	for j in 1..per_page_data.count
		commit = per_page_data[j]&.css('.Link--primary')

		if !commit&.first.nil? &&  !commit.first&.attributes.nil?
			commit_url = "https://github.com#{commit.first.attributes['href'].value}"
			commit_html = URI.open(commit_url)
			commit_response = Nokogiri::HTML(commit_html)
			commit_data = commit_response.search('[@id="files_tab_counter"]')

			if !commit_data&.first.nil? &&  !commit_data.first&.attributes.nil?	
				if commit_data.first.attributes['title'].value.to_i > 1
					urls << {commit_name: commit.text, url: commit_url}
				end
			end
		end
	end
end

header = ["S.No", "Commit Name", "Url"]

CSV.open("pull_request.csv", "wb") do |csv|
	csv << header
	urls.each_with_index do |value, index|
	  csv << ["#{index+1}",value[:commit_name], value[:url]]
	end
end
