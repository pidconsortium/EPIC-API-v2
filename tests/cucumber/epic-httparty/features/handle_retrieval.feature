Feature: EPIC-API-v2 test for retrieving PIDs
The EPIC Service is asked for Handles that are existing and not existing

Scenario Outline: Retrieve exiting and not existing Handles
  Given I use service "http://127.0.0.1:8082"
  When I accept JSON
	When I BASIC authenticate as the user "oschmitt" with the password "__CHANGE_ME__"
	When I request GET /handles/11022/<handle_id>	
  Then the http-return-code must be "<http-code>"
  
Examples:
| handle_id                          | http-code |
| 00-GWDG00000000002F-X-AFTER-UPDATE | 200       |
| 00-NOTEXISTING                     | 404       |