import ballerina/http;
import ballerina/log;
import ballerinax/health.clients.hl7;
import ballerinax/health.hl7v2;
import ballerinax/health.hl7v23 as _;
import ballerinax/health.hl7v24;

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

    } else if parsedMessage.name.startsWith("ADT") {
        hl7v2:Message|error? sendHl7MessageResult = hl7Client->sendMessage(parsedMessage);
        if sendHl7MessageResult is error {
            log:printError("Failed to send HL7v2 message to HL7 service", sendHl7MessageResult);
            return error("Failed to send HL7v2 message to HL7 service",
                    httpStatusCode = 500,
                    errorCode = "E020 SERVICE_UNAVAILABLE",
                    errorMessage = "Failed to send HL7v2 message to HL7 service: " + sendHl7MessageResult.message()
                );
        }
        if sendHl7MessageResult is hl7v24:ACK {
            if sendHl7MessageResult.msa.msa1 == "AA" {
                log:printInfo("HL7v2 message acknowledged with success: " + sendHl7MessageResult.msa.msa1);
            } else {
                log:printWarn("HL7v2 Admit message acknowledged with non-success status: " + sendHl7MessageResult.msa.msa1);
            }
            return check hl7v2:encode("2.4", sendHl7MessageResult);
        }
    } else {
        log:printError("Received unsupported HL7 message: " + parsedMessage.name);
        return error("Unsupported HL7 message type: " + parsedMessage.name,
                httpStatusCode = 400,
                errorCode = "E021 UNSUPPORTED_MESSAGE_TYPE",
                errorMessage = "Unsupported HL7 message type: " + parsedMessage.name
            );
    }
    return error("Error occurred while sending HL7v2 message",
                httpStatusCode = 500,
                errorCode = "E021 SEND_ERROR",
                errorMessage = "Error occurred while sending HL7v2 message"
            );
}
