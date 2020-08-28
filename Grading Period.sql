SELECT 
	CONCAT(main.SchoolId, '_', main.SchoolYear, '_', d.CodeValue) AS GradingPeriodID
	, main.PeriodSequence AS PeriodSequence
	--, COUNT(d.CodeValue) OVER (ORDER BY main.EndDate, d.CodeValue) AS PeriodSequence
	, main.SchoolId AS SchoolID 
	, CONCAT('SY', main.SchoolYear, '-', RIGHT(main.SchoolYear - 1, 2)) AS SchoolYear
	, d.CodeValue AS [Type] 
	, main.BeginDate AS BeginDate
	, main.EndDate AS EndDate
	, d.ShortDescription AS GradingPeriodName
	, CONCAT(RIGHT(main.SchoolYear-1, 2), '-', RIGHT(main.SchoolYear, 2), ' ', d.ShortDescription) AS GradingPeriodNameLong
	
FROM edfi.GradingPeriod AS main

LEFT JOIN edfi.Descriptor AS d
	ON main.GradingPeriodDescriptorId = d.DescriptorId