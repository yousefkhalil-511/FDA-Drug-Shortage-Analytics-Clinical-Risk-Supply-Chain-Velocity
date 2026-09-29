SELECT * FROM drug_shortages

-- 1. create fact_drug_shortages table
CREATE OR REPLACE VIEW fact_drug_shortages AS
SELECT 
	id AS shortage_id,
	package_ndc,
	generic_name,
	company_name,
	dosage_form,
	presentation,
	status,
	COALESCE(availability, 'Unspecified') AS availability,
	COALESCE(shortage_reason, 'Not Reported') AS shortage_reason,
	update_type,
	initial_posting_date,
	update_date,
	discontinued_date,
	
	-- Extract primary route from JSONB array
	COALESCE(openfda->'route'->>0, 'Not Stated') AS primary_route,

	-- Categorize Formulations (Sterile Injectables carry higher hospital operational risk
	CASE 
		WHEN dosage_form ILIKE '%inject%' OR dosage_form ILIKE '%solution%' THEN 'Sterile Injectable'
        WHEN dosage_form ILIKE '%tablet%' OR dosage_form ILIKE '%capsule%' THEN 'Oral Solid'
        WHEN dosage_form ILIKE '%suspension%' OR dosage_form ILIKE '%liquid%' THEN 'Oral Liquid'
		ELSE 'Other Formulation' 
	END AS formulation_class,

	-- Clinical Risk & Severity Tiering
	CASE 
		WHEN status = 'Current' AND availability = 'Unavailable' THEN 'Tier 1 - Critical Deficit'
		WHEN status = 'Current' AND availability = 'Limited Availability' THEN 'Tier 2 - Allocation Restricted'
		WHEN status = 'Current' AND availability = 'Available' THEN 'Tier 3 - Monitored / Recovering'
		WHEN status = 'To Be Discontinued' THEN 'Tier 4 - Market Exit'
		WHEN status = 'Resolved' THEN 'Tier 5 - Resolved'
		ELSE 'Others'
	END AS severity_tier,

	-- Aging & Velocity Metrics (in days)
	CASE 
		WHEN status = 'Current' THEN (CURRENT_DATE - initial_posting_date)
	END AS active_shortage_duration_days,
	CASE
		WHEN status = 'Resolved' THEN (update_date - initial_posting_date)
	END AS days_to_resolution,
	(CURRENT_DATE - update_date) AS days_since_last_update,
	(CURRENT_DATE - initial_posting_date) AS aging,

	-- computed Aging Buckets
	CASE 
        WHEN (CURRENT_DATE - initial_posting_date) <= 90 THEN '0-90 Days'
        WHEN (CURRENT_DATE - initial_posting_date) <= 180 THEN '91-180 Days'
        WHEN (CURRENT_DATE - initial_posting_date) <= 365 THEN '181-365 Days'
        WHEN (CURRENT_DATE - initial_posting_date) <= 730 THEN '1-2 Years'
        ELSE '> 2 Years (Chronic)'
    END AS aging_bucket,

	-- Sorting helper for aging buckets
	CASE 
        WHEN (CURRENT_DATE - initial_posting_date) <= 90 THEN 1
        WHEN (CURRENT_DATE - initial_posting_date) <= 180 THEN 2
        WHEN (CURRENT_DATE - initial_posting_date) <= 365 THEN 3
        WHEN (CURRENT_DATE - initial_posting_date) <= 730 THEN 4
        ELSE 5
    END AS aging_bucket_sort

FROM drug_shortages;

SELECT * FROM fact_drug_shortages

-- 2. create dim_therapeutic_category table
CREATE OR REPLACE VIEW dim_therapeutic_category AS
SELECT DISTINCT
    id AS shortage_id,
    TRIM(category.val) AS therapeutic_category
FROM drug_shortages,
     LATERAL unnest(therapeutic_category) AS category(val)
WHERE category.val IS NOT NULL AND category.val <> '';

SELECT * FROM dim_therapeutic_category



	