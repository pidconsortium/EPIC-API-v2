Feature: EPIC-API-v2 test for updating PIDs

Scenario: Create a Handle and Update it with PUT
  Given I use service "http://127.0.0.1:8082"
  When I accept JSON
  When I BASIC authenticate as the user "oschmitt" with the password "__CHANGE_ME__"
  When I POST a handle in the format JSON of Type URL with the value "http://www.example.net/test" to "/handles/11022/"
  When I PUT a update of the previously created handle in the format JSON of Type URL with the value "http://www.example.net/update"
  Then the http-return-code must be "204"
  # 204 means "no Content" -> Update sucessful