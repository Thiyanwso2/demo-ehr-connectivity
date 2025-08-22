import ballerina/http;
import ballerina/log;
import ballerinax/health.hl7v23 as _;
import ballerinax/health.clients.hl7;
import ballerinax/health.clients.fhir;
import thiyanarumugam/imaging.connector;

// Config parameter
configurable Config[] configs = ?;

// Service
service /api on new http:Listener(8080) {

    resource function post appointments(@http:Payload json payload) returns json|string|error {
        SynapseBookingMessage message = check payload.cloneWithType();
        string connectionName = message.connectionName;
        foreach Config config in configs {
            if config.CONNECTION_NAME == connectionName {
                string protocol = config.PROTOCOL;

                match protocol.toUpperAscii() {
                    "HL7" => {
                        log:printInfo("Routing to HL7 processing method");
                        return processHL7Message(message, ());
                    }
                    "FHIR" => {
                        log:printInfo("Routing to FHIR processing method");
                        return processFHIRMessage(message, ());
                    }
                    "REST" => {
                        log:printInfo("Routing to HTTP processing method");
                        return check processRESTMessage(message, ());
                    }
                    "ANY" => {
                        log:printInfo("Broadcasting to all systems (HL7, FHIR, HTTP)");
                        return processAnyProtocol(message);
                    }
                    _ => {
                        return error("Unsupported protocol: " + protocol);
                    }
                }
            }
        }
    }
}

function processAnyProtocol(SynapseBookingMessage message) returns json {
    ProtocolResult[] results = [];
    int successCount = 0;
    
    //loop through clients map
    foreach string connectionName in clients.keys() {
        any 'client = clients.get(connectionName);
        if 'client is hl7:HL7Client {
            log:printInfo("Processing HL7 for connection: " + connectionName);
            json|error result = processHL7Message(message, 'client);
            if result is json {
                results.push({
                    protocol: "HL7",
                    status: "success",
                    result: result
                });
                successCount += 1;
            } else {
                results.push({          
                    protocol: "HL7",
                    status: "error",
                    errorMessage: result.message()
                });
            }
        } else if 'client is fhir:FHIRConnector {
            log:printInfo("Processing FHIR for connection: " + connectionName);
            json|error result = processFHIRMessage(message, 'client);
            if result is json {
                results.push({
                    protocol: "FHIR",
                    status: "success",
                    result: result
                });
                successCount += 1;
            } else {
                results.push({
                    protocol: "FHIR",
                    status: "error",
                    errorMessage: result.message()
                });
            }
        } else if 'client is connector:Client {
            log:printInfo("Processing REST for connection: " + connectionName);
            json|error result = processRESTMessage(message, 'client);
            if result is json {
                results.push({
                    protocol: "REST",
                    status: "success",
                    result: result
                });
                successCount += 1;
            } else {
                results.push({
                    protocol: "REST",
                    status: "error",
                    errorMessage: result.message()
                });
            }
        }
    }

    // // Process HL7
    // json|error hl7Result = processHL7Message(message);
    // if hl7Result is json {
    //     ProtocolResult hl7ProtocolResult = {
    //         protocol: "HL7",
    //         status: "success",
    //         result: hl7Result
    //     };
    //     results.push(hl7ProtocolResult);
    //     successCount += 1;
    //     log:printInfo("HL7 processing completed successfully");
    // } else {
    //     ProtocolResult hl7ProtocolResult = {
    //         protocol: "HL7",
    //         status: "error",
    //         errorMessage: hl7Result.message()
    //     };
    //     results.push(hl7ProtocolResult);
    //     log:printError("HL7 processing failed", hl7Result);
    // }
    
    // // Process FHIR
    // json|error fhirResult = processFHIRMessage(message);
    // if fhirResult is json {
    //     ProtocolResult fhirProtocolResult = {
    //         protocol: "FHIR",
    //         status: "success",
    //         result: fhirResult
    //     };
    //     results.push(fhirProtocolResult);
    //     successCount += 1;
    //     log:printInfo("FHIR processing completed successfully");
    // } else {
    //     ProtocolResult fhirProtocolResult = {
    //         protocol: "FHIR",
    //         status: "error",
    //         errorMessage: fhirResult.message()
    //     };
    //     results.push(fhirProtocolResult);
    //     log:printError("FHIR processing failed", fhirResult);
    // }
    
    // // Process REST
    // json|error restResult = processRESTMessage(message);
    // if restResult is json {
    //     ProtocolResult restProtocolResult = {
    //         protocol: "REST",
    //         status: "success",
    //         result: restResult
    //     };
    //     results.push(restProtocolResult);
    //     successCount += 1;
    //     log:printInfo("REST processing completed successfully");
    // } else {
    //     ProtocolResult restProtocolResult = {
    //         protocol: "REST",
    //         status: "error",
    //         errorMessage: restResult.message()
    //     };
    //     results.push(restProtocolResult);
    //     log:printError("REST processing failed", restResult);
    // }
    
    // Create aggregated response
    string overallStatus = successCount > 0 ? "partial_success" : "failed";
    if successCount == 3 {
        overallStatus = "success";
    }
    
    string responseMessage = string `Processed ${successCount} out of 3 protocols successfully`;
    
    AggregatedResponse aggregatedResponse = {
        overallStatus: overallStatus,
        message: responseMessage,
        results: results,
        successCount: successCount,
        totalCount: 3
    };
    
    return aggregatedResponse.toJson();
}