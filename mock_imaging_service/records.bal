public type ImagingStudy record {|
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
