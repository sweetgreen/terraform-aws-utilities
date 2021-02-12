#################################################################
# REQUEST QUOTA INCREASE CODE GENERATOR
# This script generates the code for add more resources into the
# module. It only generates the code for the resources that
# 'Adjustable' is true.
# Usage:
# ruby generate_code.rb
#################################################################

require 'json'

SERVICE = 'iam'

# Some services are not available in all regions. For example, 'route53' and 'iam'
# are only available in 'us-east-1'
REGION = 'us-east-1'

def to_camel_case str 
	"#{SERVICE.capitalize}#{str.gsub('-', ' ').split(' ').collect(&:capitalize).join}"
end

def to_snake_case str
	"#{SERVICE.downcase}_#{str.downcase.gsub(" ", "_").gsub('-', '_')}"
end

quotas = JSON.parse(`aws service-quotas list-service-quotas --service-code #{SERVICE} --region #{REGION} | jq '[ .Quotas[] | select(.Adjustable) ]'`)

to_terraform = quotas.map do |quota|
	"""#{to_snake_case(quota['QuotaName'])} = {
  quota_name   = \"#{quota['QuotaName']}\"
  service_code = \"#{quota['ServiceCode']}\"
},"""
end

puts "###### Add into modules/main.tf ######"
puts "\n"
puts to_terraform
puts "\n"

to_example = quotas.map do |quota|
	"#{to_snake_case(quota['QuotaName'])} = #{quota['Value']},"
end
puts "###### Add into examples/main.tf ######"
puts "\n"
puts to_example
puts "\n"

to_test = quotas.map do |quota|
	"""
  assert.Equal(t, output.#{to_camel_case(quota['QuotaName'])}.QuotaName, \"#{quota['QuotaName']}\")
  assert.Equal(t, output.#{to_camel_case(quota['QuotaName'])}.ServiceName, \"#{quota['ServiceName']}\")
  """
end

puts "\n"
puts "###### Changes to test/request_quota_increase_test.go ######"
puts "###### Add into the TestRequestQuotaIncrease function ######"
puts "\n"
puts to_test

to_struct = quotas.map do |quota|
	"#{to_camel_case(quota['QuotaName'])} QuotaAndServiceName `json:\"#{to_snake_case(quota['QuotaName'])}\"` "
end

puts "\n"
puts "###### Add this into 'QuotaIncreaseOutput' struct ######"
puts "\n"
puts to_struct