Then(/^the "(.+)" of the top non-bugsnag stackframe equals (\d+|".+")$/) do |element, value|
  stacktrace = read_key_path(Server.current_request[:body], 'events.0.exceptions.0.stacktrace')
  frame_index = stacktrace.find_index { |frame| ! /.*lib\/bugsnag.*\.rb/.match(frame["file"]) }
  steps %Q{
    the "#{element}" of stack frame #{frame_index} equals #{value}
  }
end

Then(/^the total sessionStarted count equals (\d+)$/) do |value|
  session_counts = read_key_path(Server.current_request[:body], "sessionCounts")
  total_count = session_counts.inject(0) { |count, session| count += session["sessionsStarted"] }
  assert_equal(value, total_count)
end


# Due to an ongoing discussion on whether the `payload_version` needs to be present within the headers
# and body of the payload, this step is a local replacement for the similar step present in the main
# maze-runner library. Once the discussion is resolved this step should be removed and replaced in scenarios
# with the main library version.
Then("the request is valid for the error reporting API version {string} for the {string}") do |payload_version, notifier_name|
  steps %Q{
    Then the "Bugsnag-Api-Key" header equals "#{$api_key}"
    And the payload field "apiKey" equals "#{$api_key}"
    And the "Bugsnag-Payload-Version" header equals "#{payload_version}"
    And the "Content-Type" header equals "application/json"
    And the "Bugsnag-Sent-At" header is a timestamp

    And the payload field "notifier.name" equals "#{notifier_name}"
    And the payload field "notifier.url" is not null
    And the payload field "notifier.version" is not null
    And the payload field "events" is a non-empty array

    And each element in payload field "events" has "severity"
    And each element in payload field "events" has "severityReason.type"
    And each element in payload field "events" has "unhandled"
    And each element in payload field "events" has "exceptions"
  }
end

Given("I start the rails service") do
  rails_version = ENV["RAILS_VERSION"]
  steps %Q{
    When I start the service "rails#{rails_version}"
    And I wait for the host "rails#{rails_version}" to open port "3000"
  }
end

When("I navigate to the route {string} on the rails app") do |route|
  rails_version = ENV["RAILS_VERSION"]
  steps %Q{
    When I open the URL "http://rails#{rails_version}:3000#{route}"
  }
end

Then("the payload field {string} matches the appropriate Sidekiq handled payload") do |field|
  if ENV["SIDEKIQ_VERSION"] == "~> 2"
    created_at_present = "false"
  else
    created_at_present = "true"
  end
  steps %Q{
    And the payload field "#{field}" matches the JSON fixture in "features/fixtures/sidekiq/payloads/handled_metadata_ca_#{created_at_present}.json"
  }
end

Then("the payload field {string} matches the appropriate Sidekiq unhandled payload") do |field|
  if ENV["SIDEKIQ_VERSION"] == "~> 2"
    created_at_present = "false"
  else
    created_at_present = "true"
  end
  steps %Q{
    And the payload field "#{field}" matches the JSON fixture in "features/fixtures/sidekiq/payloads/unhandled_metadata_ca_#{created_at_present}.json"
  }
end
