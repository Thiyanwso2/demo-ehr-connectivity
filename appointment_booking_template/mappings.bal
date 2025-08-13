import ballerina/uuid;
import ballerinax/health.fhir.r4.international401;
import ballerinax/health.hl7v24;

function createBookingResponseForHL7(hl7v24:ACK sendHl7MessageResult, string connectionName) returns json {
    if sendHl7MessageResult.msa.msa1 == "AA" {
        return {
            status: "success",
            message: "Appointment created successfully in: " + connectionName
        };
    }
    return {
        status: "error",
        message: "Failed to create appointment in: " + connectionName
    };
}

function mapAppointmentDataToHL7(AppointmentData r) returns hl7v24:ORM_O01 => {
    msh: {
        msh2: "^~\\&",
        msh3: {hd1: "TESTSERVER"},
        msh4: {hd1: "WSO2"},
        msh9: {msg1: "ORM", msg2: "O01"},
        msh10: uuid:createType1AsString().substring(0, 8),
        msh11: {pt1: "P"},
        msh12: {vid1: "2.4"}
    },
    patient: {
        pid: {
            pid1: r.patientId,
            pid5: [
                {
                    xpn1: {
                        fn1: r.patientFamilyName
                    },
                    xpn2: r.patientGivenName
                }
            ],
            pid7: {
                ts1: r.patientBirthDate
            },
            pid8: r.patientGender
        }
    },
    'order: [
        {
            orc: {
                orc1: "NW",
                orc2: {
                    ei1: r.locationId,
                    ei2: (r.locationName != ()) ? <string>r?.locationName : ""
                },
                orc10: [
                    {
                        xcn1: r.practitionerId,
                        xcn2: {
                            fn1: r.practitionerId,
                            fn2: (r.practitionerName != ()) ? <string>r?.practitionerName : ""
                        }
                    }
                ]
            }
        }
    ]
};

public function mapAppointmentDataToFHIR(AppointmentData custom) returns international401:Appointment => {
    participant: [
        {
            actor: {
                reference: "Practitioner/" + custom.practitionerId
            },
            status: "needs-action"
        },
        {
            actor: {
                reference: "Location/" + custom.locationId
            },
            status: "needs-action"
        }
    ],
    status: "proposed",
    slot: [
        {
            reference: "Slot/24477854-21304876-62852027-0"
        }
    ],
    serviceType: [
        {
            coding: [
                {
                    system: "http://snomed.info/sct",
                    code: "408443003"
                }
            ]
        }
    ],
    requestedPeriod: [
        {
            'start: custom.startTime,
            end: custom.endTime
        }
    ],
    reasonCode: [
        {
            text: custom.reasonText
        }
    ]
};
