Feature: EPIC-API-v2 test for deleting PIDs

Scenario: Create a Handle with POST and create it afterwards
	Given I use service "http://127.0.0.1:8082"
  When I accept JSON
  When I BASIC authenticate as the user "oschmitt" with the password "__CHANGE_ME__"
  When I POST a handle in the format JSON of Type URL with the value "http://www.example.net/test" to "/handles/11022/"
  When I DELETE the previously created handle
  Then the http-return-code must be "204"
  # 204 means no content -> Delete was successful 