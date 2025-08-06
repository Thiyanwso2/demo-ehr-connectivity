import ballerinax/health.fhir.r4.international401;

public isolated function transform(CustomImagingStudy imagingstudy) returns ImagingStudy => {
    // id: imagingstudy.id.toBalString(),
    subject: {},
    status: <international401:ImagingStudyStatus>imagingstudy.status

};


