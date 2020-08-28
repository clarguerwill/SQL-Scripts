SELECT main.StudentUniqueId AS LocalStudentID
	, usi.IdentificationCode AS USI 
	, NULL AS AlternateStudentID
	, CONCAT(main.LastSurname, ', ', main.FirstName) AS [Name]
	, sex.CodeValue AS Sex
	, main.Birthdate AS Birthdate
	, [current].GradeLevel AS CurrentGradeLevel
	, [current].DescriptorId AS GradeSort
	, CASE
		WHEN [current].ExitWithdrawDate IS NULL THEN NULL
		WHEN COALESCE([current].ExitWithdrawDate,(CONCAT('20',(RIGHT([current].SchoolYear,2)),'-06-30')))>getdate() THEN 'Active'
		ELSE 'Not Active' 
		END AS EnrollStatus
	, [current].SchoolName AS CurrentSchool
	, race.Race AS Race
	, ethnicity.HispanicLatinoEthnicity AS HispanicLatinoEthnicity
	, CASE 
		WHEN ethnicity.HispanicLatinoEthnicity = 1 THEN 'Hispanic/Latino'
		WHEN ethnicity.HispanicLatinoEthnicity = 0 THEN race.Race
		ELSE NULL
		END AS RaceEthnicity
	, CASE 
		WHEN disability.IEP IS NULL THEN 'Not IEP'
		ELSE 'IEP' 
		END AS IEP
	, CASE 
		WHEN disability.Section504Plan IS NULL THEN 'No 504Plan'
		ELSE '504Plan' 
		END AS Section504Plan
	, CASE 
		WHEN characteristic.AtRisk IS NULL THEN 'Not At-Risk'
		ELSE 'At-Risk'
		END AS AtRisk
	, CASE
		WHEN lep.LimitedEnglishProficiencyDescriptorId IS NULL THEN 'Not LEP'
		ELSE 'LEP' 
		END AS LimitedEnglishProficiency
	, CASE 
		WHEN characteristic.Homeless IS NULL THEN 'Not Homeless'
		ELSE 'Homeless'
		END AS Homeless
	, CASE 
		WHEN characteristic.Lunch = '15' THEN 'Free'
		WHEN characteristic.Lunch = '16' THEN 'Reduced'
		ELSE 'Full Price'
		END AS SchoolFoodServiceEligibility
	, house.IdentificationCode AS Cohort
	, CASE WHEN ninth.SchoolYear IS NOT NULL THEN 
		CONCAT('SY', ninth.SchoolYear, '-', RIGHT(ninth.SchoolYear - 1, 2)) 
		ELSE NULL 
		END AS First9thGradeYear
	, NULL AS YearsAtLEA -- All years don't exist in edfi beacsue their enrollment is incorrect before 19-20
	, NULL AS ServiceHours
	, ad.[Address] AS [Adress]
	, NULL AS Ward

FROM edfi.Student AS main


-- Getting USI
LEFT JOIN (
	SELECT I.*, D.CodeValue AS [Value]
	FROM edfi.StudentEducationOrganizationAssociationStudentIdentificationCode AS I 
	LEFT JOIN edfi.Descriptor AS D
		ON I.StudentIdentificationSystemDescriptorId = D.DescriptorId) AS usi
	
	ON main.StudentUSI = usi.StudentUSI
	AND usi.[Value] = 'USI'


-- Getting Sex
LEFT JOIN edfi.Descriptor AS sex
	ON main.BirthSexDescriptorId = sex.DescriptorId


-- Getting CurrentGradeLevel, CurrentSchool and EnrollStatus
LEFT JOIN (
	SELECT C.StudentUSI, eo.ShortNameOfInstitution AS SchoolName, D.CodeValue AS GradeLevel
		, D.DescriptorId, C.ExitWithdrawDate, w.CodeValue AS ExitType, C.SchoolYear
	FROM (
		SELECT ROW_NUMBER() OVER (PARTITION BY StudentUSI ORDER BY EntryDate DESC) row_num, *
		FROM [edfi].[StudentSchoolAssociation]
		) AS C

	LEFT JOIN edfi.EducationOrganization AS eo
		ON C.SchoolId = eo.EducationOrganizationId

	LEFT JOIN edfi.Descriptor AS D
		ON C.EntryGradeLevelDescriptorId = D.DescriptorId

	LEFT JOIN edfi.Descriptor AS w
		ON C.ExitWithdrawTypeDescriptorId = w.DescriptorId

	WHERE row_num = 1) AS [current]

	ON main.StudentUSI = [current].StudentUSI


-- Getting Race
LEFT JOIN (
	SELECT R.StudentUSI, R.AllRaces, D.CodeValue, CASE 
		WHEN R.AllRaces IS NULL THEN NULL 
		WHEN D.CodeValue IS NOT NULL THEN D.CodeValue
		WHEN D.CodeValue IS NULL THEN 'Two or More Races'
		END AS Race

	FROM (
		SELECT *, CONCAT(
				(CASE WHEN [8] IS NULL THEN NULL ELSE [8] END),
				(CASE WHEN [9] IS NULL THEN NULL ELSE [9] END),
				(CASE WHEN [10] IS NULL THEN NULL ELSE [10] END),
				(CASE WHEN [11] IS NULL THEN NULL ELSE [11] END),
				(CASE WHEN [12] IS NULL THEN NULL ELSE [12] END)
			) as AllRaces
		FROM
			(SELECT StudentUSI, RaceDescriptorId
			FROM edfi.StudentEducationOrganizationAssociationRace) AS sourcetable

		PIVOT(MAX(RaceDescriptorId) FOR RaceDescriptorId IN ([8], [9], [10], [11], [12])) AS pvt
		) AS R

	LEFT JOIN edfi.Descriptor AS D
	ON R.AllRaces = D.DescriptorId

	) AS Race

	ON main.StudentUSI = race.StudentUSI


-- Getting Ethnicity
LEFT JOIN edfi.StudentEducationOrganizationAssociation AS ethnicity
	ON main.StudentUSI = ethnicity.StudentUSI


-- Getting IEP and Secttion504Plan
LEFT Join (
	SELECT *
		, CASE WHEN [5] IS NOT NULL THEN [5] ELSE NULL END AS IEP
		, CASE WHEN [6] IS NOT NULL THEN [6] ELSE NULL END AS Section504Plan
		FROM
			(SELECT StudentUSI, DisabilityDescriptorId
			FROM edfi.StudentEducationOrganizationAssociationDisability) AS sourcetable

		PIVOT(MAX(DisabilityDescriptorID) FOR DisabilityDescriptorID IN ([5], [6])) AS pvt) AS disability
	ON main.StudentUSI = disability.StudentUSI


-- Getting LimitedEnglishProficiency
LEFT JOIN edfi.StudentEducationOrganizationAssociation AS lep
	ON main.StudentUSI = lep.StudentUSI
		   

-- Getting FoodElgibility, Homeless and At-Risk 
LEFT JOIN(
	SELECT StudentUSI, [17] AS AtRisk, [18] AS Homeless, 
		CONCAT(
			(CASE WHEN [15] IS NULL THEN NULL ELSE [15] END),
			(CASE WHEN [16] IS NULL THEN NULL ELSE [16] END)
			) AS Lunch 
	FROM
		(SELECT StudentUSI, StudentCharacteristicDescriptorId AS CharacteristicId
		FROM edfi.StudentEducationOrganizationAssociationStudentCharacteristic) AS sourcetable

	PIVOT(MAX(CharacteristicId) FOR CharacteristicId IN ([15], [16], [17], [18])) AS pvt
	) AS characteristic
	ON main.StudentUSI = characteristic.StudentUSI


-- Getting USI
LEFT JOIN (
	SELECT I.*, D.CodeValue AS [Value]
	FROM edfi.StudentEducationOrganizationAssociationStudentIdentificationCode AS I 
	LEFT JOIN edfi.Descriptor AS D
		ON I.StudentIdentificationSystemDescriptorId = D.DescriptorId) AS house
	
	ON main.StudentUSI = house.StudentUSI
	AND house.[Value] = 'House'


-- Getting First9thGradeYear
LEFT JOIN edfi.StudentEducationOrganizationAssociationCohortYear AS ninth
	ON main.StudentUSI = ninth.StudentUSI

-- Getting Address 
LEFT JOIN (
	SELECT StudentUSI
		, A.StreetNumberName+COALESCE(' '+A.ApartmentRoomSuiteNUmber,'')+COALESCE(' '+A.BuildingSiteNUmber,'')+COALESCE(' '+A.City,'')+COALESCE(' '+st.CodeValue,'')+COALESCE(' '+A.PostalCode,'') AS [Address]
	FROM edfi.StudentEducationOrganizationAssociationAddress AS A

	LEFT JOIN edfi.Descriptor AS st
		ON A.StateAbbreviationDescriptorId = st.DescriptorId ) AS ad

	ON main.StudentUSI = ad.StudentUSI





