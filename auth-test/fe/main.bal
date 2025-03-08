import ballerina/http;

configurable string backendUrl = ?;

final http:Client backendClient = check new (backendUrl);

service / on new http:Listener(9090) {
    resource function get greet(string name, string author) returns string|error {
        string greetingFromBE = check backendClient->/greet(name = name);
        return string `${greetingFromBE}, from ${author}`;
    } 
}
