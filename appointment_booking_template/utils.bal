// import ballerinax/health.fhir.r4.international401
import thiyanarumugam/imaging.connector;
import ballerina/http;
import ballerina/log;
import ballerina/url;
import ballerinax/health.clients.fhir;
import ballerinax/health.clients.hl7;
import ballerinax/health.hl7v2;
import ballerinax/health.hl7v23 as _;
import ballerinax/health.hl7v24;

map<any> clients = {};

function init() returns error? {

    foreach Config config in configs {
        match config.PROTOCOL.toUpperAscii() {
            "HL7" => {
                int port = <int>config.PORT;
                string host = <string>config.HOST;
                hl7:HL7Client hl7Client = check new (host, port);
                clients[config.CONNECTION_NAME] = hl7Client;
            }
            "FHIR" => {
                string serverUrl = <string>config.SERVER_URL;
                string tokenUrl = <string>config.TOKEN_URL;
                string clientId = <string>config.CLIENT_ID;
                string clientSecret = <string>config.CLIENT_SECRET;
                string[] scopes = [];
                (string[] & readonly)? temp = config.SCOPES;
                if temp is string[] & readonly {
                    scopes = temp;
                }

                http:ClientAuthConfig authConfig = {
                    tokenUrl: tokenUrl,
                    clientId: clientId,
                    clientSecret: clientSecret,
                    scopes: scopes
                };
                fhir:FHIRConnectorConfig connectorConfig = {
                    baseURL: serverUrl,
                    authConfig: authConfig
                };
                fhir:FHIRConnector connector = check new (connectorConfig);
                clients[config.CONNECTION_NAME] = connector;
            }
            "REST" => {
                string serverUrl = <string>config.SERVER_URL;
                connector:Client imagingClient = check new ({}, serverUrl);
                clients[config.CONNECTION_NAME] = imagingClient;
            }
        }
    }

}

// Stub processing methods
public function processHL7Message(SynapseBookingMessage message) returns json|error {

    hl7:HL7Client hl7Client = <hl7:HL7Client>clients.get(message.connectionName);
    hl7v2:Message|hl7v2:HL7Error parsedMessage = mapAppointmentDataToHL7(message.data);
    if parsedMessage is hl7v2:HL7Error {
        return error("Failed to parse the HL7 message",
                httpStatusCode = 400,
                errorCode = "E019 PARSE_ERROR",
                errorMessage = "Failed to parse the HL7 message"
            );

    } else if parsedMessage.name.startsWith("ORM") {
        byte[]|hl7v2:HL7Error encode = hl7v2:encode("2.4", parsedMessage);
        if encode is byte[] {
            log:printInfo("Mapped AppointmentData to HL7v2 ORM_O01 message: ", mappedData = check string:fromBytes(encode));
        }
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
            return createBookingResponseForHL7(sendHl7MessageResult, message.connectionName);
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

public function processFHIRMessage(SynapseBookingMessage message) returns json|error {

    fhir:FHIRConnector connector = <fhir:FHIRConnector>clients.get(message.connectionName);
    json jsonResult = mapAppointmentDataToFHIR(message.data).toJson();
    log:printInfo("Mapped Appointment data to FHIR: ", mappedData = jsonResult);
    fhir:FHIRResponse|fhir:FHIRError fHIRResponse = connector->create(jsonResult);
    if fHIRResponse is fhir:FHIRError {
        log:printError("Failed to create appointment", fHIRResponse);
        return error("Failed to create appointment",
            httpStatusCode = 500,
            errorCode = "E022 FHIR_CREATION_ERROR",
            errorMessage = "Failed to create appointment: " + fHIRResponse.message()
        );
    }
    json bookingResponseForFHIR = createBookingResponseForFHIR(fHIRResponse, message.connectionName);
    return bookingResponseForFHIR;
}

public function processHTTP(SynapseBookingMessage message) returns json|error {

    connector:Client 'client = <connector:Client>clients.get(message.connectionName);
    connector:AppointmentImaging mapAppointmentDataToImagingDataResult = mapAppointmentDataToREST(message.data);
    connector:AppointmentImaging|error imagingStudy = 'client->/imagingStudy.post(mapAppointmentDataToImagingDataResult);
    log:printInfo("Mapped Appointment data to Imaging Study: ", mappedData = mapAppointmentDataToImagingDataResult.toJson());
    if imagingStudy is error {
        log:printError("Failed to create appointment in Imaging Study", imagingStudy);
        return error("Failed to create appointment in Imaging Study",
            httpStatusCode = 500,
            errorCode = "E023 IMAGING_CREATION_ERROR",
            errorMessage = "Failed to create appointment in Imaging Study: " + imagingStudy.message()
        );
    }
    log:printInfo("Successfully created appointment in Imaging Lab", imagingStudy = imagingStudy.toJson());
    json bookingResponseForREST = createBookingResponseForREST(imagingStudy, message.connectionName);
    return bookingResponseForREST;
}

# Get Encoded URI for a given value.
#
# + value - Value to be encoded
# + return - Encoded string
isolated function getEncodedUri(anydata value) returns string {
    string|error encoded = url:encode(value.toString(), "UTF8");
    if encoded is string {
        return encoded;
    } else {
        return value.toString();
    }
}
