SELECT main.SchoolId AS LocalSchoolID
	, school.NameOfInstitution AS SchoolNameLong 
	, school.ShortNameOfInstitution AS SchoolNameShort
	, 283 AS OSSECode
	, [level].SchoolLevel AS SchoolLevel 
	, D.CodeValue AS SchoolType
	, NULL AS Campus
	, [level].DescriptorId AS LevelSort

FROM edfi.School AS main


-- Getting SchoolNameLong and SchoolNameShort
LEFT JOIN edfi.EducationOrganization AS school
	ON main.SchoolId = school.EducationOrganizationId


-- Getting SchoolLevel
LEFT JOIN (
	SELECT C.SchoolID, C.SchoolCategoryDescriptorId, D.CodeValue AS SchoolLevel, D.DescriptorId
	FROM edfi.SchoolCategory AS C
	LEFT JOIN edfi.Descriptor AS D
		ON C.SchoolCategoryDescriptorId = D.DescriptorId) AS [level]

	ON main.SchoolId = [level].SchoolId
	

-- Getting SchoolType
LEFT JOIN edfi.Descriptor AS D
	ON main.SchoolTypeDescriptorId = D.DescriptorId
