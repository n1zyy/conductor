World(Rack::Test::Methods)

Given /^I use my authentication credentials in each request$/ do
  authorize(@user.login, 'secret')
end

When /^I request a list of providers returned as XML$/ do
  header 'Accept', 'application/xml'
  get api_providers_path
end

Then /^I should receive list of providers as XML$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(200)
  xml_body = Nokogiri::XML(response.body)
  xml_body.xpath('//providers/provider').size.should be_eql(3)
end

When /^I ask for details of that provider as XML$/ do
  header 'Accept', 'application/xml'
  get api_provider_path(@provider.id)
end

Then /^I should receive details of that provider as XML$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(200)
  xml_body = Nokogiri::XML(response.body)
  xml_body.xpath('//provider').size.should be_eql(1)
end

When /^I ask for details of non existing provider as XML$/ do
  header 'Accept', 'application/xml'
  provider = Provider.find_by_id(1)
  provider.delete if provider
  get api_provider_path(1)
end

Then /^I should receive Not Found error$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(404)
  xml_body = Nokogiri::XML(response.body)
  xml_body.xpath('//error').size.should be_eql(1)
end

When /^I create provider with correct data via XML$/ do
  header 'Accept', 'application/xml'
  header 'Content-Type', 'application/xml'

  @provider = FactoryGirl.build(:mock_provider)

  xml_provider = %Q[<?xml version="1.0" encoding="UTF-8"?>
                    <provider>
                    <name>#{@provider.name}</name>
                    <url>#{@provider.url}</url>
                    <provider_type id="#{@provider.provider_type_id}" />
                    </provider>
                    ]

  post api_providers_path, xml_provider
end

Then /^I should received?(?: an)? OK message$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(200)
end

When /^I create provider with incorrect data via XML$/ do
  header 'Accept', 'application/xml'
  header 'Content-Type', 'application/xml'

  @provider = FactoryGirl.build(:invalid_provider)

  xml_provider = %Q[<?xml version="1.0" encoding="UTF-8"?>
                    <provider>
                    <name>#{@provider.name}</name>
                    <url>#{@provider.url}</url>
                    <provider_type_id>#{@provider.provider_type_id}</provider_type_id>
                    </provider>
                    ]

  post api_providers_path, xml_provider
end

Then /^I should receive Bad Request message$/ do
  response = last_response
  response.headers['Content-Type'].should include('application/xml')
  response.status.should be_eql(400)
end
