json fhir_appointment = {
    "resourceType":"Appointment",
    "status":"proposed",
    "slot":[
        {
            "reference":"Slot/24477854-21304876-62852027-0"
        }
    ],
    "serviceType": [
      {
        "coding": [
          {
            "code": "408443003",
            "system": "http://snomed.info/sct"
          }
        ]
      }
    ],
    "participant":[
        {
            "actor":{
                "reference":"Patient/12970521"
            },
            "status":"needs-action"
        },
        {
        "actor": {
          "reference": "Location/21304876",
          "display": "MX Clinic 1"
        },
        "status": "needs-action"
      }
    ],
    "requestedPeriod": [
      {
        "start": "2023-02-07T13:28:17-05:00",
        "end": "2023-02-08T13:28:17-05:00"
      }
    ],
    "reasonCode":[
        {
            "text":"I have a cramp"
        }
    ]
};

json imagingData = {
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
