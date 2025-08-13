import ballerina/http;
import ballerina/log;
import ballerinax/health.hl7v23 as _;

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
                        return processHL7Message(message);
                    }
                    "FHIR" => {
                        log:printInfo("Routing to FHIR processing method");
                        return processFHIR(message);
                    }
                    "HTTP" => {
                        log:printInfo("Routing to HTTP processing method");
                        return check processHTTP(message);
                    }
                    _ => {
                        return error("Unsupported protocol: " + protocol);
                    }
                }
            }
        }
    }
}

