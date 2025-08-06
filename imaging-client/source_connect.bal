public isolated function getById(string id) returns ImagingStudy|error{
    CustomImagingStudy response = check httpClient->get(string `/imagingStudy/${id}`);
    ImagingStudy transformResult = transform(response);
    return transformResult;
}