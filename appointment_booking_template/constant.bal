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