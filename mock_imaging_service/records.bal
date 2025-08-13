// public type ImagingStudy record {|
//     string resourceType = "ImagingStudy";
//     int id?;
//     string status;
//     string subject;
//     string started?;
//     Series[] series?;
// |};

// public type Series record {|
//     string uid;
//     string modality;
//     string description?;
//     Instance[] instances?;
// |};

// public type Instance record {|
//     string uid;
//     string sopClass;
//     string title?;
// |};


public type AppointmentImaging record {|
    string resourceType = "Appointment";
    int id?;
    string status;                 // proposed | pending | booked | arrived | fulfilled | cancelled | noshow
    string appointmentType?;       // e.g., "Imaging Session", "Lab Test"
    string 'start;                  // ISO datetime
    string end;                    // ISO datetime
    string description?;           // e.g., "MRI Brain Scan" or "Blood Panel"

    PatientReference patient;      // Patient information
    LocationReference location;    // Where the session/test will take place
    PractitionerReference? practitioner; // Assigned practitioner, if known

    ServiceDetail[] serviceDetails?; // Imaging modalities or lab tests requested
|};

public type PatientReference record {|
    string id;                     // Patient ID or MRN
    string displayName;            // Full name
|};

public type LocationReference record {|
    string id;                     // Location/department code
    string displayName;            // e.g., "Radiology Department"
|};

public type PractitionerReference record {|
    string id;                     // Practitioner ID
    string displayName;            // Practitioner name
|};

public type ServiceDetail record {|
    string code;                   // e.g., modality code "CT", "MRI", "BLOOD"
    string description?;           // Human-readable name of the procedure
|};
