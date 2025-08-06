import ballerinax/health.fhir.r4.international401;

public isolated function getById(string id) returns ImagingStudy|error {
    CustomImagingStudy response = check httpClient->get(string `/imagingStudy/${id}`);
    ImagingStudy transformResult = transform(response);
    return transformResult;
}

public isolated function transform(CustomImagingStudy imagingstudy) returns ImagingStudy => {
    id: imagingstudy.id.toBalString(),
    subject: {
        reference: imagingstudy.subject
    },
    status: <international401:ImagingStudyStatus>imagingstudy.status,
    started: imagingstudy.started,
    series: mapSeries(imagingstudy.series)
};

isolated function mapSeries(Series[]? series) returns international401:ImagingStudySeries[] {
    international401:ImagingStudySeries[] imagingStudySeries = [];

    if series is Series[] {
        foreach Series s in series {
            international401:ImagingStudySeries imgSeries = {
                uid: s.uid,
                modality: {code: s.modality},
                description: s.description,
                instance: mapSeriesInstance(s.instances)
            };
            imagingStudySeries.push(imgSeries);
        }
    }
    return imagingStudySeries;

}

isolated function mapSeriesInstance(Instance[]? instances) returns international401:ImagingStudySeriesInstance[] {
    international401:ImagingStudySeriesInstance[] imgInstances = [];

    if instances is Instance[] {
        foreach Instance i in instances {
            international401:ImagingStudySeriesInstance imgInstance = {
                uid: i.uid,
                sopClass: {code: i.sopClass},
                title: i.title
            };
            imgInstances.push(imgInstance);
        }
    }
    return imgInstances;
}

public type CustomImagingStudy record {|
    string resourceType = "ImagingStudy";
    int id?;
    string status;
    string subject;
    string started?;
    Series[] series?;
|};

public type Series record {|
    string uid;
    string modality;
    string description?;
    Instance[] instances?;
|};

public type Instance record {|
    string uid;
    string sopClass;
    string title?;
|};
