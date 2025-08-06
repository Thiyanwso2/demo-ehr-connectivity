import ballerina/http;

// In-memory storage (Map)
isolated map<ImagingStudy> imagingStudyStore = {};
isolated int id = 102;

// Service Definition
service /imagingStudy on new http:Listener(8585) {

    // Create ImagingStudy (POST /imagingStudy)
    isolated resource function post .(http:Request req) returns error|http:Response {
        json payload = check req.getJsonPayload();
        ImagingStudy newStudy = check payload.cloneWithType(ImagingStudy);

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
    isolated resource function get [string id]() returns ImagingStudy|http:NotFound {
        lock {
            if imagingStudyStore.hasKey(id) {
                ImagingStudy? study = imagingStudyStore[id];
                if study is ImagingStudy {
                    return imagingStudyStore.clone().get(id);
                }
            }
            return <http:NotFound>{body: {message: "ImagingStudy not found"}};
        }
    }
}

function init() returns error? {
    json data = {
        "id": 102,
        "status": "available",
        "subject": "Patient/123",
        "started": "2025-08-06T10:00:00Z",
        "series": [
            {
                "uid": "1.2.3.4",
                "modality": "CT",
                "description": "Head CT Scan",
                "instances": [
                    {
                        "uid": "1.2.3.4.5.6",
                        "sopClass": "1.2.840.10008.5.1.4.1.1.2",
                        "title": "Image 1"
                    }
                ]
            }
        ]
    };

    ImagingStudy imagingStudy = check data.cloneWithType(ImagingStudy);
    lock {
        imagingStudyStore[imagingStudy.id.toBalString()] = imagingStudy.clone();
    }
}
