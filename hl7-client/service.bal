import ballerina/http;
import ballerina/log;
import ballerinax/health.clients.hl7;
import ballerinax/health.hl7v2;

configurable string backendUrl = ?;
configurable int port = ?;

hl7:HL7Client hl7Client;

function init() returns error? {
    hl7Client = check new (backendUrl, port);
}

service /api/admit on new http:Listener(8080) {
    resource function post .(@http:Payload string payload, http:Request request, http:Caller caller) returns error? {
        byte[] admitRequestResult = check sendAdmitRequest(payload);
        check caller->respond(admitRequestResult);
    }
}

public function sendAdmitRequest(string request) returns byte[]|error {

    hl7v2:Message|hl7v2:HL7Error parsedMessage = hl7v2:parse(request);
    if parsedMessage is hl7v2:HL7Error {
        return error("Failed to parse the HL7 message",
                httpStatusCode = 400,
                errorCode = "E019 PARSE_ERROR",
                errorMessage = "Failed to parse the HL7 message"
            );

    } else {
        byte[]|hl7v2:HL7Error encodedMessage = hl7v2:encode("2.4", parsedMessage);
        if encodedMessage is hl7v2:HL7Error {
            return error("Failed to encode HL7v2 message: " + encodedMessage.message(),
                    httpStatusCode = 500,
                    errorCode = "E024 HL7_ENCODING_ERROR",
                    errorMessage = "Failed to encode HL7v2 message: " + encodedMessage.message()
                );
        }
        log:printInfo("Encoded HL7 message", message = encodedMessage.toString());
        hl7v2:Message|error? sendHl7MessageResult = hl7Client->sendMessage(parsedMessage);
        if sendHl7MessageResult is error {
            log:printError("Failed to send HL7v2 message to mock HL7 service", sendHl7MessageResult);
            return error("Failed to send HL7v2 message to mock HL7 service",
                    httpStatusCode = 500,
                    errorCode = "E019 SERVICE_UNAVAILABLE",
                    errorMessage = "Failed to send HL7v2 message to mock HL7 service: " + sendHl7MessageResult.message()
                );
        }
        if sendHl7MessageResult is hl7v2:Message {
            return check hl7v2:encode("2.4", sendHl7MessageResult);
        }
    }
    return error("Failed to send HL7v2 message to service provider, no response received",
                httpStatusCode = 500,
                errorCode = "E019 SERVICE_UNAVAILABLE",
                errorMessage = "Failed to send HL7v2 message to service provider, no response received"
            );
}
