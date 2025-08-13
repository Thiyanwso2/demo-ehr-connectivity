import ballerina/http;

// In-memory storage (Map)
isolated map<AppointmentImaging> imagingStudyStore = {};
isolated int id = 1001;

// Service Definition
service /imagingStudy on new http:Listener(8585) {

    // Create ImagingStudy (POST /imagingStudy)
    isolated resource function post .(http:Request req) returns error|http:Response {
        json payload = check req.getJsonPayload();
        AppointmentImaging newStudy = check payload.cloneWithType(AppointmentImaging);

        lock {
            int tempId = id + 1;
            newStudy.id = tempId;
            id = tempId.clone();
        }
        lock {
            imagingStudyStore[newStudy.id.toBalString()] = newStudy.clone();
        }

        http:Response response = new;
        response.setPayload(newStudy.toJson());
        response.statusCode = http:STATUS_ACCEPTED;
        return response;
    }

    // Get ImagingStudy by ID (GET /imagingStudy/{id})
    isolated resource function get [string id]() returns AppointmentImaging|http:NotFound {
        lock {
            if imagingStudyStore.hasKey(id) {
                AppointmentImaging? study = imagingStudyStore[id];
                if study is AppointmentImaging {
                    return imagingStudyStore.clone().get(id);
                }
            }
            return <http:NotFound>{body: {message: "Imaging appointment not found"}};
        }
    }
}

function init() returns error? {
    json data = {
        "resourceType": "Appointment",
        "id": 1001,
        "status": "booked",
        "appointmentType": "Imaging Session",
        "start": "2025-08-20T10:30:00Z",
        "end": "2025-08-20T11:00:00Z",
        "description": "MRI Brain Scan with contrast",

        "patient": {
            "id": "pat-2024",
            "displayName": "John Doe"
        },

        "location": {
            "id": "loc-001",
            "displayName": "Radiology Department - Main Hospital"
        },

        "practitioner": {
            "id": "prac-451",
            "displayName": "Dr. Sarah Wilson"
        },

        "serviceDetails": [
            {
                "code": "MRI",
                "description": "Magnetic Resonance Imaging - Brain"
            }
        ]
    };

    AppointmentImaging imagingStudy = check data.cloneWithType(AppointmentImaging);
    lock {
        imagingStudyStore[imagingStudy.id.toBalString()] = imagingStudy.clone();
    }
}
