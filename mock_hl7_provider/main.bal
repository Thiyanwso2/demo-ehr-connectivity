import ballerina/log;
import ballerina/tcp;
import ballerina/uuid;
import ballerinax/health.hl7v2;
import ballerinax/health.hl7v24;

service on new tcp:Listener(3000) {
    remote function onConnect(tcp:Caller caller) returns tcp:ConnectionService {
        log:printInfo("Client connected to HL7 server: " + caller.remotePort.toString());
        return new HL7ServiceConnectionService();
    }
}

service class HL7ServiceConnectionService {
    *tcp:ConnectionService;

    remote function onBytes(tcp:Caller caller, readonly & byte[] data) returns tcp:Error? {
        string|error fromBytes = string:fromBytes(data);
        if fromBytes is string {
            log:printInfo("Received HL7 Message: " + fromBytes);
        }

        // Note: When you know the message type you can directly get it parsed.
        hl7v2:Message|error parsedMsg = hl7v2:parse(data);
        if parsedMsg is error {
            return error(string `Error occurred while parsing the received message: ${parsedMsg.message()}`,
            parsedMsg);
        }

        hl7v24:ACK ack = {
            msh: {
                msh1: "|",
                msh2: "^~\\&",
                msh3: {
                    hd1: "ReceivingApp" // Receiver (from original ADT)
                },
                msh4: {
                    hd1: "ReceivingFac" // Receiver Facility (from original ADT)
                },
                msh5: {
                    hd1: "SendingApp" // Sender (from original ADT)
                },
                msh6: {
                    hd1: "SendingFac" // Sender Facility (from original ADT)
                },
                msh7: {
                    ts1: "2025-08-05T10:31:00" // Current timestamp
                },
                msh9: {
                    msg1: "ACK",
                    msg2: "A01" // Message Trigger Event (optional but clearer)
                },
                msh10: uuid:createType1AsString().substring(0, 8), // Unique Control ID
                msh11: {
                    pt1: "P"
                },
                msh12: {
                    vid1: hl7v24:VERSION
                },
                msh15: "AL", // Accept Acknowledgment Type (Always)
                msh17: "44", // Country Code
                msh18: ["ASCII"] // Character Set
            },
            msa: {
                msa1: "AA", // Acknowledgment Code (Application Accept)
                msa2: "123456" // Echo back Message Control ID from original ADT
            }
        };

        byte[]|hl7v2:HL7Error encode = hl7v2:encode("2.4", ack);
        if encode is byte[] {
            string|error fromBytesResult = string:fromBytes(encode);
            if fromBytesResult is string {
                log:printInfo("ACK Message: " + fromBytesResult);
            }
            tcp:Error? writeBytes = caller->writeBytes(encode);
            if writeBytes is tcp:Error {
                log:printError("Error occurred while sending ACK message: ", writeBytes);
            }
        }
    }

    remote function onError(tcp:Error err) {
        log:printError("An error occurred while receiving HL7 message: ", err);
    }

    remote function onClose() {
        log:printInfo("Client left");
    }
}
