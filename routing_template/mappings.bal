import ballerinax/health.fhir.r4.international401;
import ballerinax/health.hl7v24;

function mapHL7ToJson(hl7v24:ACK sendHl7MessageResult) returns json {
    return {};
}

function mapAppointmentDataToHL7(AppointmentData r) returns string {
    return string `MSH|^~\&|MESA_ADT|XYZ_ADMITTING|iFW|XYZ|||ADT^A01|MESA1|P|2.4
EVN||202408051000
PID|1||12345^MRN|56789^ANOTHER_ID||Doe^John||19800101|M|||123 Main St^^Anytown^CA^91234
PV1|1|I|Lobby^101|||||12345^Doctor^John`;
}

public function mapAppointmentDataToFHIR(AppointmentData custom) returns international401:Appointment => {
    participant: [],
    status: "checked-in"
};
