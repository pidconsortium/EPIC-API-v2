Feature: EPIC-API-v2 test for Basic Authentication
We test, if the authentication works.

Scenario: Perform a GET on /handles without any authentication
  Given I use service "http://127.0.0.1:8082"
  When I accept JSON
	And I ignore all authentication
	When I request GET /handles
  Then the http-return-code must be "401"
  
Scenario Outline: Perform a GET on handles with valid and invalid credentials
  Given I use service "http://127.0.0.1:8082"
  When I accept JSON
  When I BASIC authenticate as the user "<username>" with the password "<password>"
  When I request GET /handles
  Then the http-return-code must be "<http-code>"

Examples:

| username | password      | http-code |
| oschmitt | __CHANGE_ME__ | 200       |
| malory   | evaandbob     | 401       |