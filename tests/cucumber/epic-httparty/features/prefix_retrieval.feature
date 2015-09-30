Feature: EPIC-API-v2 test for retrieving prefixes
The EPIC Service is asked about all prefixes and the lowest one is read

Scenario: Retrieve all prefixes and check the prefix with the lowest value against a given value
  Given I use service "http://127.0.0.1:8082"
  When I accept JSON
  When I BASIC authenticate as the user "oschmitt" with the password "__CHANGE_ME__"
  When I request GET /handles
  Then the lowest prefix in the system is "11022/"
  Then the http-return-code must be "200"