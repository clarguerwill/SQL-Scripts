-- The code is split into three parts: main1, main2, and main3
-- main1 columns are calculated first, main2 second, main3 third


--------------------------------- Start of main3 -----------------------------
SELECT -- Get necessary main1 and main2 columns -- 
	main3.DateAndSchoolID AS DateSchoolID
	, main3.SchoolID
	, main3.[Date]
	, main3.[Day]
	, main3.DaySort
	, main3.[Month]
	, main3.MonthSort
	, main3.FlagInstructionDay
	, main3.StartofWeek
	, main3.SchoolYear
	, main3.MostRecentDate
	, main3.ShiftedDate
	, main3.InstructionalDay
	, main3.FlagCACheck

	-- main3 columns -- 
	, term.SessionName AS Term
	, CASE
		WHEN main3.ShiftedDate <= main3.MostRecentDate THEN 1
		ELSE 0 
		END AS FlagforKPI
	, CASE -- Kenli has this code, but I feel like it doesn't need the CASE and we can just skip to the value
		WHEN main3.[Date] <= main3.MostRecentDate THEN DATEDIFF(year, main3.[Date], main3.ShiftedDate) 
		ELSE NULL
		END AS YearsAgo
	

FROM (
--------------------------------- Start of main2 -----------------------------
	SELECT main2.* -- Get all main1 columns --

		-- main2 columns -- 
		, CASE
	 		WHEN MONTH(main2.[Date])=2 AND DAY(main2.[Date])=29 -- Leap Year Calculation
				THEN DATEFROMPARTS(YEAR(main2.[Date]) + (main2.MostRecentEndYear - (CAST(RIGHT(main2.SYear,2)AS INT))-2000)
					,MONTH(main2.[Date]),28) -- Shifts leap years to the 28th
			ELSE DATEFROMPARTS(YEAR(main2.[Date]) + (main2.MostRecentEndYear - (CAST(RIGHT(main2.SYear,2)AS INT))-2000)
				,MONTH(main2.[Date])
				,DAY(main2.[Date])) 
			END AS ShiftedDate 
		, CASE 
			WHEN main2.InstructionalDay IS NULL THEN 0
			WHEN main2.InstructionalDay % 10 = 0 THEN 1
			ELSE 0
			END AS FlagCACheck

	FROM (
--------------------------------- Start of main1 -----------------------------
		SELECT main1.DateAndSchoolID AS DateAndSchoolID
			, main1.SchoolId AS SchoolID
			, main1.[Date] AS [Date]
			, DATENAME(WEEKDAY, main1.[Date]) AS [Day]
			, DATEPART(WEEKDAY, main1.[Date]) AS DaySort
			, DATENAME(MONTH, main1.[Date]) AS [Month]
			, CASE 
				WHEN DATEPART(MONTH, main1.[Date]) >= 8 THEN DATEPART(MONTH, main1.[Date]) - 7
				ELSE DATEPART(MONTH, main1.[Date]) + 5
				END AS MonthSort
			, flag.InstructionalDay AS FlagInstructionDay
			, DATEADD(DAY, 1 - DATEPART(WEEKDAY, main1.[Date]), main1.[Date]) AS StartofWeek
			, CONCAT('SY', main1.SchoolYear -1, '-', RIGHT(main1.SchoolYear, 2)) AS SchoolYear
			, main1.SchoolYear AS SYear -- Needed for main2 calculations (Does not show in output)
			, most.RecentDate AS MostRecentDate
			, most.RecentEndYear AS MostRecentEndYear -- Needed for main2 calculations (Does not show in output)
			, flag.InstructionalDayCount AS InstructionalDay

		FROM (SELECT cd.*, CONCAT(cd.[Date], '_', cd.SchoolId) AS DateAndSchoolID FROM edfi.CalendarDate AS cd) AS main1


		-- Getting FlagInstructionalDay and InstructionalDay for main1
		LEFT JOIN (
			SELECT CONCAT(cdce.[Date], '_', cdce.SchoolId) AS DateAndSchoolID
				, SUM(CASE WHEN cdce.[Date] IS NOT NULL THEN 1 ELSE 0 END) 
					OVER (PARTITION BY cdce.SchoolYear, cdce.SchoolId ORDER BY cdce.[Date] ROWS UNBOUNDED PRECEDING)
				AS InstructionalDayCount
				, 1 AS InstructionalDay
			FROM edfi.CalendarDateCalendarEvent AS cdce
			LEFT JOIN edfi.Descriptor AS D 
				ON cdce.CalendarEventDescriptorId = D.DescriptorId
			WHERE D.CodeValue = 'Instructional Day'
			) AS flag

			ON main1.DateAndSchoolID = flag.DateAndSchoolID


		-- Getting MostRecentDate and MostRecentEndYear for main1
		JOIN (
			SELECT MAX([Date]) AS RecentDate
				, MAX(SchoolYear) AS RecentEndYear
			FROM edfi.CalendarDateCalendarEvent 
			WHERE [Date] < GETDATE()
			) AS most 

			ON 1=1
----------------------------------^ End of main1 ^-----------------------------


		) AS main2
----------------------------------^ End of main2 ^-----------------------------


	) AS main3

LEFT JOIN edfi.[Session] AS term
	ON main3.SchoolId = term.SchoolId 
	AND term.SessionName IN ('Q1', 'Q2', 'Q3', 'Q4')
	AND term.BeginDate <= main3.[Date] 
	AND term.EndDate >= main3.[Date]

ORDER BY main3.SchoolId, main3.[Date] DESC -- Necessary to get the Term

----------------------------------^ End of main3 ^-----------------------------


