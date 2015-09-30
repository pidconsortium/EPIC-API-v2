Feature: EPIC-API-v2 test for creating PIDs

Scenario: Create a Handle with POST and data in JSON-format
  Given I use service "http://127.0.0.1:8082"
  When I accept JSON
  When I BASIC authenticate as the user "oschmitt" with the password "__CHANGE_ME__"
  When I POST a handle in the format JSON of Type URL with the value "http://www.example.net/test" to "/handles/11022/"
  Then the http-return-code must be "201"
  Then the http-header contains a field with the name "location"
    
Scenario: Create a Handle with POST on an existing resource
	Given I use service "http://127.0.0.1:8082"
  When I accept JSON
  When I BASIC authenticate as the user "oschmitt" with the password "__CHANGE_ME__"
  When I POST a handle in the format JSON of Type URL with the value "http://www.example.net/test" to "/handles/11022/"
  When I POST test data to the previously created handle
  Then the http-return-code must be "405" 
  # 405 means "Method not allowed"