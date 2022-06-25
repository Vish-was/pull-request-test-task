# pull-request-test-task



#### For runnig the program on your local system

1. You need to install ruby on your local system
2. Open your terminal on linux/Macos or Cmdprompt in Window
3. Type -  ruby /path/to/pull_request.rb
4. After running program successfully. You will find pull_request.csv file in your home directory.



### Some Details About The Program

As per requirement, we need to scraping a pull request for list all the PR which have changes in multiple files.

For scraping with ruby, we have used Nokogiri to fetch the data in html::xml format with given url. 

## require 'nokogiri', 'open-uri' to fetch the data in html format and parsed.
require 'nokogiri'
require 'open-uri'

url = 'https://github.com/rails/rails'
html = URI.open(url)
doc = Nokogiri::HTML(html)

#Nokogiri::HTML(html) this will fetch the data from the tempfile and parsed into xml:document

search_tab = doc.search('[@id="pull-requests-tab"]')

we are searching the pull request tab to find its href link for jump on that page.
Now we have fetch the particular link of that PR page,

pull_request_tab_url  = "https://github.com#{search_tab.first.attributes['href'].value}"
pull_request_tab_html = URI.open(pull_request_tab_url)
doc_pull_request_tab  = Nokogiri::HTML(pull_request_tab_html)

we again parsing PR page html in Nokogiri doc. And finding the total no. of pages in pagniation link from the bottom of the page.

### find the html element with the css and fetch out the total page value 
 
total_page_css = doc_pull_request_tab.css('.current')
total_page = total_page_css.first.attributes['data-total-pages'].value.to_i

Now we put loop on each page to find those PR which have changes in mulitple files and save its 
url path and commit name in urls variable.

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

And then we prepare a csv to list all the PRs.

header = ["S.No", "Commit Name", "Url"]

CSV.open("pull_request.csv", "wb") do |csv|
	csv << header
	urls.each_with_index do |value, index|
	  csv << ["#{index+1}",value[:commit_name], value[:url]]
	end
end






